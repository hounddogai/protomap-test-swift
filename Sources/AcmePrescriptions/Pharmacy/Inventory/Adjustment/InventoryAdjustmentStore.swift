import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory adjustments by code.
    protocol InventoryAdjustmentStore {
        func find(_ code: String) -> InventoryAdjustment?
        func save(_ item: InventoryAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryAdjustmentStore: InventoryAdjustmentStore {
        var items: [String: InventoryAdjustment]
        var order: [String]

        init(items: [String: InventoryAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryAdjustment) {
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

        func list() -> [InventoryAdjustment] {
            var out: [InventoryAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryAdjustmentStore() -> any InventoryAdjustmentStore {
        return MemoryInventoryAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryAdjustmentStore: InventoryAdjustmentStore {
        var inner: MemoryInventoryAdjustmentStore
        var cache: TTLCache<InventoryAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryAdjustmentStore, cache: TTLCache<InventoryAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryAdjustment? {
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

        func save(_ item: InventoryAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryAdjustment] {
            return inner.list()
        }
    }

    static func newCachedInventoryAdjustmentStore(_ inner: MemoryInventoryAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryAdjustmentStore {
        return CachedInventoryAdjustmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory adjustments. Empty fields match all.
    final class InventoryAdjustmentQuery {
        var label: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventoryAdjustment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InventoryAdjustment]) -> [InventoryAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryAdjustments(_ store: any InventoryAdjustmentStore, query: InventoryAdjustmentQuery) -> [InventoryAdjustment] {
        return query.apply(store.list())
    }
}
