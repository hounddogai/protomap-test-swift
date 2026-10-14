import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps weighted formulary estimates by code.
    protocol WeightedFormularyEstimateStore {
        func find(_ code: String) -> WeightedFormularyEstimate?
        func save(_ item: WeightedFormularyEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedFormularyEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedFormularyEstimateStore: WeightedFormularyEstimateStore {
        var items: [String: WeightedFormularyEstimate]
        var order: [String]

        init(items: [String: WeightedFormularyEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedFormularyEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedFormularyEstimate) {
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

        func list() -> [WeightedFormularyEstimate] {
            var out: [WeightedFormularyEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedFormularyEstimateStore() -> any WeightedFormularyEstimateStore {
        return MemoryWeightedFormularyEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedFormularyEstimateStore: WeightedFormularyEstimateStore {
        var inner: MemoryWeightedFormularyEstimateStore
        var cache: TTLCache<WeightedFormularyEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedFormularyEstimateStore, cache: TTLCache<WeightedFormularyEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedFormularyEstimate? {
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

        func save(_ item: WeightedFormularyEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedFormularyEstimate] {
            return inner.list()
        }
    }

    static func newCachedWeightedFormularyEstimateStore(_ inner: MemoryWeightedFormularyEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedFormularyEstimateStore {
        return CachedWeightedFormularyEstimateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted formulary estimates. Empty fields match all.
    final class WeightedFormularyEstimateQuery {
        var label: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minAmount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedFormularyEstimate) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedFormularyEstimate]) -> [WeightedFormularyEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedFormularyEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedFormularyEstimates(_ store: any WeightedFormularyEstimateStore, query: WeightedFormularyEstimateQuery) -> [WeightedFormularyEstimate] {
        return query.apply(store.list())
    }
}
