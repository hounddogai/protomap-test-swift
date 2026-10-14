import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan variances by code.
    protocol DischargePlanVarianceStore {
        func find(_ code: String) -> DischargePlanVariance?
        func save(_ item: DischargePlanVariance)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanVarianceStore: DischargePlanVarianceStore {
        var items: [String: DischargePlanVariance]
        var order: [String]

        init(items: [String: DischargePlanVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanVariance) {
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

        func list() -> [DischargePlanVariance] {
            var out: [DischargePlanVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanVarianceStore() -> any DischargePlanVarianceStore {
        return MemoryDischargePlanVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanVarianceStore: DischargePlanVarianceStore {
        var inner: MemoryDischargePlanVarianceStore
        var cache: TTLCache<DischargePlanVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanVarianceStore, cache: TTLCache<DischargePlanVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanVariance? {
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

        func save(_ item: DischargePlanVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanVariance] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanVarianceStore(_ inner: MemoryDischargePlanVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanVarianceStore {
        return CachedDischargePlanVarianceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan variances. Empty fields match all.
    final class DischargePlanVarianceQuery {
        var name: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCost: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanVariance) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [DischargePlanVariance]) -> [DischargePlanVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanVariances(_ store: any DischargePlanVarianceStore, query: DischargePlanVarianceQuery) -> [DischargePlanVariance] {
        return query.apply(store.list())
    }
}
