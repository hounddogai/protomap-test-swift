import AcmePlatform
import Foundation

extension Labs {
    /// Keeps weighted reference range estimates by code.
    protocol WeightedReferenceRangeEstimateStore {
        func find(_ code: String) -> WeightedReferenceRangeEstimate?
        func save(_ item: WeightedReferenceRangeEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedReferenceRangeEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedReferenceRangeEstimateStore: WeightedReferenceRangeEstimateStore {
        var items: [String: WeightedReferenceRangeEstimate]
        var order: [String]

        init(items: [String: WeightedReferenceRangeEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedReferenceRangeEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedReferenceRangeEstimate) {
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

        func list() -> [WeightedReferenceRangeEstimate] {
            var out: [WeightedReferenceRangeEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedReferenceRangeEstimateStore() -> any WeightedReferenceRangeEstimateStore {
        return MemoryWeightedReferenceRangeEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedReferenceRangeEstimateStore: WeightedReferenceRangeEstimateStore {
        var inner: MemoryWeightedReferenceRangeEstimateStore
        var cache: TTLCache<WeightedReferenceRangeEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedReferenceRangeEstimateStore, cache: TTLCache<WeightedReferenceRangeEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedReferenceRangeEstimate? {
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

        func save(_ item: WeightedReferenceRangeEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedReferenceRangeEstimate] {
            return inner.list()
        }
    }

    static func newCachedWeightedReferenceRangeEstimateStore(_ inner: MemoryWeightedReferenceRangeEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedReferenceRangeEstimateStore {
        return CachedWeightedReferenceRangeEstimateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted reference range estimates. Empty fields match all.
    final class WeightedReferenceRangeEstimateQuery {
        var unit: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedReferenceRangeEstimate) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedReferenceRangeEstimate]) -> [WeightedReferenceRangeEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedReferenceRangeEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedReferenceRangeEstimates(_ store: any WeightedReferenceRangeEstimateStore, query: WeightedReferenceRangeEstimateQuery) -> [WeightedReferenceRangeEstimate] {
        return query.apply(store.list())
    }
}
