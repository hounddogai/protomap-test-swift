import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation rollups by code.
    protocol IsolationRollupStore {
        func find(_ code: String) -> IsolationRollup?
        func save(_ item: IsolationRollup)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationRollupStore: IsolationRollupStore {
        var items: [String: IsolationRollup]
        var order: [String]

        init(items: [String: IsolationRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationRollup) {
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

        func list() -> [IsolationRollup] {
            var out: [IsolationRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationRollupStore() -> any IsolationRollupStore {
        return MemoryIsolationRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationRollupStore: IsolationRollupStore {
        var inner: MemoryIsolationRollupStore
        var cache: TTLCache<IsolationRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationRollupStore, cache: TTLCache<IsolationRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationRollup? {
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

        func save(_ item: IsolationRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationRollup] {
            return inner.list()
        }
    }

    static func newCachedIsolationRollupStore(_ inner: MemoryIsolationRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationRollupStore {
        return CachedIsolationRollupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation rollups. Empty fields match all.
    final class IsolationRollupQuery {
        var ward: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minBudget: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationRollup) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [IsolationRollup]) -> [IsolationRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationRollups(_ store: any IsolationRollupStore, query: IsolationRollupQuery) -> [IsolationRollup] {
        return query.apply(store.list())
    }
}
