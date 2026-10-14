import AcmePlatform
import Foundation

extension Labs {
    /// Keeps default courier preferences by code.
    protocol DefaultCourierPreferenceStore {
        func find(_ code: String) -> DefaultCourierPreference?
        func save(_ item: DefaultCourierPreference)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultCourierPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultCourierPreferenceStore: DefaultCourierPreferenceStore {
        var items: [String: DefaultCourierPreference]
        var order: [String]

        init(items: [String: DefaultCourierPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultCourierPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultCourierPreference) {
            if !(items[item.code] != nil) {
                order.append(item.code)
            }
            items[item.code] = item
        }

        func remove(_ code: String) -> Bool {
            if !(items[code] != nil) {
                return false
            }
            items.removeValue(forKey: code)
            var kept: [String] = []
            for existing in order {
                if existing != code {
                    kept.append(existing)
                }
            }
            order = kept
            return true
        }

        func list() -> [DefaultCourierPreference] {
            var out: [DefaultCourierPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultCourierPreferenceStore() -> any DefaultCourierPreferenceStore {
        return MemoryDefaultCourierPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultCourierPreferenceStore: DefaultCourierPreferenceStore {
        var inner: MemoryDefaultCourierPreferenceStore
        var cache: TTLCache<DefaultCourierPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultCourierPreferenceStore, cache: TTLCache<DefaultCourierPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultCourierPreference? {
            guard let hit = cache.getValue(code) else {
                misses += 1
                guard let found = inner.find(code) else {
                    return nil
                }
                cache.put(code, value: found)
                return found
            }
            hits += 1
            return hit
        }

        func save(_ item: DefaultCourierPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultCourierPreference] {
            return inner.list()
        }
    }

    static func newCachedDefaultCourierPreferenceStore(_ inner: MemoryDefaultCourierPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultCourierPreferenceStore {
        return CachedDefaultCourierPreferenceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default courier preferences. Empty fields match all.
    final class DefaultCourierPreferenceQuery {
        var name: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minSequence: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultCourierPreference) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultCourierPreference]) -> [DefaultCourierPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultCourierPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultCourierPreferences(_ store: any DefaultCourierPreferenceStore, query: DefaultCourierPreferenceQuery) -> [DefaultCourierPreference] {
        return query.apply(store.list())
    }
}
