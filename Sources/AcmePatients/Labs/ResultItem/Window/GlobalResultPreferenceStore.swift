import AcmePlatform
import Foundation

extension Labs {
    /// Keeps global result preferences by code.
    protocol GlobalResultPreferenceStore {
        func find(_ code: String) -> GlobalResultPreference?
        func save(_ item: GlobalResultPreference)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalResultPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalResultPreferenceStore: GlobalResultPreferenceStore {
        var items: [String: GlobalResultPreference]
        var order: [String]

        init(items: [String: GlobalResultPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalResultPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalResultPreference) {
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

        func list() -> [GlobalResultPreference] {
            var out: [GlobalResultPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalResultPreferenceStore() -> any GlobalResultPreferenceStore {
        return MemoryGlobalResultPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalResultPreferenceStore: GlobalResultPreferenceStore {
        var inner: MemoryGlobalResultPreferenceStore
        var cache: TTLCache<GlobalResultPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalResultPreferenceStore, cache: TTLCache<GlobalResultPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalResultPreference? {
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

        func save(_ item: GlobalResultPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalResultPreference] {
            return inner.list()
        }
    }

    static func newCachedGlobalResultPreferenceStore(_ inner: MemoryGlobalResultPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalResultPreferenceStore {
        return CachedGlobalResultPreferenceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global result preferences. Empty fields match all.
    final class GlobalResultPreferenceQuery {
        var unit: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minCost: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalResultPreference) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalResultPreference]) -> [GlobalResultPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalResultPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalResultPreferences(_ store: any GlobalResultPreferenceStore, query: GlobalResultPreferenceQuery) -> [GlobalResultPreference] {
        return query.apply(store.list())
    }
}
