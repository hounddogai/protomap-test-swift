import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps global inventory rollups by code.
    protocol GlobalInventoryRollupStore {
        func find(_ code: String) -> GlobalInventoryRollup?
        func save(_ item: GlobalInventoryRollup)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalInventoryRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalInventoryRollupStore: GlobalInventoryRollupStore {
        var items: [String: GlobalInventoryRollup]
        var order: [String]

        init(items: [String: GlobalInventoryRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalInventoryRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalInventoryRollup) {
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

        func list() -> [GlobalInventoryRollup] {
            var out: [GlobalInventoryRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalInventoryRollupStore() -> any GlobalInventoryRollupStore {
        return MemoryGlobalInventoryRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalInventoryRollupStore: GlobalInventoryRollupStore {
        var inner: MemoryGlobalInventoryRollupStore
        var cache: TTLCache<GlobalInventoryRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalInventoryRollupStore, cache: TTLCache<GlobalInventoryRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalInventoryRollup? {
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

        func save(_ item: GlobalInventoryRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalInventoryRollup] {
            return inner.list()
        }
    }

    static func newCachedGlobalInventoryRollupStore(_ inner: MemoryGlobalInventoryRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalInventoryRollupStore {
        return CachedGlobalInventoryRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global inventory rollups. Empty fields match all.
    final class GlobalInventoryRollupQuery {
        var unit: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalInventoryRollup) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [GlobalInventoryRollup]) -> [GlobalInventoryRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalInventoryRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalInventoryRollups(_ store: any GlobalInventoryRollupStore, query: GlobalInventoryRollupQuery) -> [GlobalInventoryRollup] {
        return query.apply(store.list())
    }
}
