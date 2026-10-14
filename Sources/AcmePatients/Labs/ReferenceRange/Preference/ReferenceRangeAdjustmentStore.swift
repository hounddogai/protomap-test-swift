import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range adjustments by code.
    protocol ReferenceRangeAdjustmentStore {
        func find(_ code: String) -> ReferenceRangeAdjustment?
        func save(_ item: ReferenceRangeAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeAdjustmentStore: ReferenceRangeAdjustmentStore {
        var items: [String: ReferenceRangeAdjustment]
        var order: [String]

        init(items: [String: ReferenceRangeAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeAdjustment) {
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

        func list() -> [ReferenceRangeAdjustment] {
            var out: [ReferenceRangeAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeAdjustmentStore() -> any ReferenceRangeAdjustmentStore {
        return MemoryReferenceRangeAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeAdjustmentStore: ReferenceRangeAdjustmentStore {
        var inner: MemoryReferenceRangeAdjustmentStore
        var cache: TTLCache<ReferenceRangeAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeAdjustmentStore, cache: TTLCache<ReferenceRangeAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeAdjustment? {
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

        func save(_ item: ReferenceRangeAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeAdjustment] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeAdjustmentStore(_ inner: MemoryReferenceRangeAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeAdjustmentStore {
        return CachedReferenceRangeAdjustmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range adjustments. Empty fields match all.
    final class ReferenceRangeAdjustmentQuery {
        var unit: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeAdjustment) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferenceRangeAdjustment]) -> [ReferenceRangeAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeAdjustments(_ store: any ReferenceRangeAdjustmentStore, query: ReferenceRangeAdjustmentQuery) -> [ReferenceRangeAdjustment] {
        return query.apply(store.list())
    }
}
