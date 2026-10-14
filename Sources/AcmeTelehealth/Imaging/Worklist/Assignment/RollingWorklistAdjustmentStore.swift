import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps rolling worklist adjustments by code.
    protocol RollingWorklistAdjustmentStore {
        func find(_ code: String) -> RollingWorklistAdjustment?
        func save(_ item: RollingWorklistAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [RollingWorklistAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingWorklistAdjustmentStore: RollingWorklistAdjustmentStore {
        var items: [String: RollingWorklistAdjustment]
        var order: [String]

        init(items: [String: RollingWorklistAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingWorklistAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingWorklistAdjustment) {
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

        func list() -> [RollingWorklistAdjustment] {
            var out: [RollingWorklistAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingWorklistAdjustmentStore() -> any RollingWorklistAdjustmentStore {
        return MemoryRollingWorklistAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingWorklistAdjustmentStore: RollingWorklistAdjustmentStore {
        var inner: MemoryRollingWorklistAdjustmentStore
        var cache: TTLCache<RollingWorklistAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingWorklistAdjustmentStore, cache: TTLCache<RollingWorklistAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingWorklistAdjustment? {
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

        func save(_ item: RollingWorklistAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingWorklistAdjustment] {
            return inner.list()
        }
    }

    static func newCachedRollingWorklistAdjustmentStore(_ inner: MemoryRollingWorklistAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingWorklistAdjustmentStore {
        return CachedRollingWorklistAdjustmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling worklist adjustments. Empty fields match all.
    final class RollingWorklistAdjustmentQuery {
        var unit: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingWorklistAdjustment) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingWorklistAdjustment]) -> [RollingWorklistAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingWorklistAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingWorklistAdjustments(_ store: any RollingWorklistAdjustmentStore, query: RollingWorklistAdjustmentQuery) -> [RollingWorklistAdjustment] {
        return query.apply(store.list())
    }
}
