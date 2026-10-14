import AcmePlatform
import Foundation

extension Labs {
    /// Keeps strict result preferences by code.
    protocol StrictResultPreferenceStore {
        func find(_ code: String) -> StrictResultPreference?
        func save(_ item: StrictResultPreference)
        func remove(_ code: String) -> Bool
        func list() -> [StrictResultPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictResultPreferenceStore: StrictResultPreferenceStore {
        var items: [String: StrictResultPreference]
        var order: [String]

        init(items: [String: StrictResultPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictResultPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictResultPreference) {
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

        func list() -> [StrictResultPreference] {
            var out: [StrictResultPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictResultPreferenceStore() -> any StrictResultPreferenceStore {
        return MemoryStrictResultPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictResultPreferenceStore: StrictResultPreferenceStore {
        var inner: MemoryStrictResultPreferenceStore
        var cache: TTLCache<StrictResultPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictResultPreferenceStore, cache: TTLCache<StrictResultPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictResultPreference? {
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

        func save(_ item: StrictResultPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictResultPreference] {
            return inner.list()
        }
    }

    static func newCachedStrictResultPreferenceStore(_ inner: MemoryStrictResultPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictResultPreferenceStore {
        return CachedStrictResultPreferenceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict result preferences. Empty fields match all.
    final class StrictResultPreferenceQuery {
        var title: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictResultPreference) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictResultPreference]) -> [StrictResultPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictResultPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictResultPreferences(_ store: any StrictResultPreferenceStore, query: StrictResultPreferenceQuery) -> [StrictResultPreference] {
        return query.apply(store.list())
    }
}
