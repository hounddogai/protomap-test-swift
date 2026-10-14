import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps weighted transfer variances by code.
    protocol WeightedTransferVarianceStore {
        func find(_ code: String) -> WeightedTransferVariance?
        func save(_ item: WeightedTransferVariance)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedTransferVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedTransferVarianceStore: WeightedTransferVarianceStore {
        var items: [String: WeightedTransferVariance]
        var order: [String]

        init(items: [String: WeightedTransferVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedTransferVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedTransferVariance) {
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

        func list() -> [WeightedTransferVariance] {
            var out: [WeightedTransferVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedTransferVarianceStore() -> any WeightedTransferVarianceStore {
        return MemoryWeightedTransferVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedTransferVarianceStore: WeightedTransferVarianceStore {
        var inner: MemoryWeightedTransferVarianceStore
        var cache: TTLCache<WeightedTransferVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedTransferVarianceStore, cache: TTLCache<WeightedTransferVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedTransferVariance? {
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

        func save(_ item: WeightedTransferVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedTransferVariance] {
            return inner.list()
        }
    }

    static func newCachedWeightedTransferVarianceStore(_ inner: MemoryWeightedTransferVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedTransferVarianceStore {
        return CachedWeightedTransferVarianceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted transfer variances. Empty fields match all.
    final class WeightedTransferVarianceQuery {
        var region: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedTransferVariance) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [WeightedTransferVariance]) -> [WeightedTransferVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedTransferVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedTransferVariances(_ store: any WeightedTransferVarianceStore, query: WeightedTransferVarianceQuery) -> [WeightedTransferVariance] {
        return query.apply(store.list())
    }
}
