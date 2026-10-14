import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps manual shift adjustments by code.
    protocol ManualShiftAdjustmentStore {
        func find(_ code: String) -> ManualShiftAdjustment?
        func save(_ item: ManualShiftAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [ManualShiftAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualShiftAdjustmentStore: ManualShiftAdjustmentStore {
        var items: [String: ManualShiftAdjustment]
        var order: [String]

        init(items: [String: ManualShiftAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualShiftAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualShiftAdjustment) {
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

        func list() -> [ManualShiftAdjustment] {
            var out: [ManualShiftAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualShiftAdjustmentStore() -> any ManualShiftAdjustmentStore {
        return MemoryManualShiftAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualShiftAdjustmentStore: ManualShiftAdjustmentStore {
        var inner: MemoryManualShiftAdjustmentStore
        var cache: TTLCache<ManualShiftAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualShiftAdjustmentStore, cache: TTLCache<ManualShiftAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualShiftAdjustment? {
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

        func save(_ item: ManualShiftAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualShiftAdjustment] {
            return inner.list()
        }
    }

    static func newCachedManualShiftAdjustmentStore(_ inner: MemoryManualShiftAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualShiftAdjustmentStore {
        return CachedManualShiftAdjustmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual shift adjustments. Empty fields match all.
    final class ManualShiftAdjustmentQuery {
        var segment: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minCost: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualShiftAdjustment) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [ManualShiftAdjustment]) -> [ManualShiftAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualShiftAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualShiftAdjustments(_ store: any ManualShiftAdjustmentStore, query: ManualShiftAdjustmentQuery) -> [ManualShiftAdjustment] {
        return query.apply(store.list())
    }
}
