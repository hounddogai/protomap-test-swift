import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps default cleaning preferences by code.
    protocol DefaultCleaningPreferenceStore {
        func find(_ code: String) -> DefaultCleaningPreference?
        func save(_ item: DefaultCleaningPreference)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultCleaningPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultCleaningPreferenceStore: DefaultCleaningPreferenceStore {
        var items: [String: DefaultCleaningPreference]
        var order: [String]

        init(items: [String: DefaultCleaningPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultCleaningPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultCleaningPreference) {
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

        func list() -> [DefaultCleaningPreference] {
            var out: [DefaultCleaningPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultCleaningPreferenceStore() -> any DefaultCleaningPreferenceStore {
        return MemoryDefaultCleaningPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultCleaningPreferenceStore: DefaultCleaningPreferenceStore {
        var inner: MemoryDefaultCleaningPreferenceStore
        var cache: TTLCache<DefaultCleaningPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultCleaningPreferenceStore, cache: TTLCache<DefaultCleaningPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultCleaningPreference? {
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

        func save(_ item: DefaultCleaningPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultCleaningPreference] {
            return inner.list()
        }
    }

    static func newCachedDefaultCleaningPreferenceStore(_ inner: MemoryDefaultCleaningPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultCleaningPreferenceStore {
        return CachedDefaultCleaningPreferenceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default cleaning preferences. Empty fields match all.
    final class DefaultCleaningPreferenceQuery {
        var title: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minLimit: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultCleaningPreference) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultCleaningPreference]) -> [DefaultCleaningPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultCleaningPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultCleaningPreferences(_ store: any DefaultCleaningPreferenceStore, query: DefaultCleaningPreferenceQuery) -> [DefaultCleaningPreference] {
        return query.apply(store.list())
    }
}
