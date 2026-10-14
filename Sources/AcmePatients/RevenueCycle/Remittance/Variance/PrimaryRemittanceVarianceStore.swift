import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps primary remittance variances by code.
    protocol PrimaryRemittanceVarianceStore {
        func find(_ code: String) -> PrimaryRemittanceVariance?
        func save(_ item: PrimaryRemittanceVariance)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryRemittanceVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryRemittanceVarianceStore: PrimaryRemittanceVarianceStore {
        var items: [String: PrimaryRemittanceVariance]
        var order: [String]

        init(items: [String: PrimaryRemittanceVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryRemittanceVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryRemittanceVariance) {
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

        func list() -> [PrimaryRemittanceVariance] {
            var out: [PrimaryRemittanceVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryRemittanceVarianceStore() -> any PrimaryRemittanceVarianceStore {
        return MemoryPrimaryRemittanceVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryRemittanceVarianceStore: PrimaryRemittanceVarianceStore {
        var inner: MemoryPrimaryRemittanceVarianceStore
        var cache: TTLCache<PrimaryRemittanceVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryRemittanceVarianceStore, cache: TTLCache<PrimaryRemittanceVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryRemittanceVariance? {
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

        func save(_ item: PrimaryRemittanceVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryRemittanceVariance] {
            return inner.list()
        }
    }

    static func newCachedPrimaryRemittanceVarianceStore(_ inner: MemoryPrimaryRemittanceVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryRemittanceVarianceStore {
        return CachedPrimaryRemittanceVarianceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary remittance variances. Empty fields match all.
    final class PrimaryRemittanceVarianceQuery {
        var unit: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minCost: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryRemittanceVariance) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [PrimaryRemittanceVariance]) -> [PrimaryRemittanceVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryRemittanceVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryRemittanceVariances(_ store: any PrimaryRemittanceVarianceStore, query: PrimaryRemittanceVarianceQuery) -> [PrimaryRemittanceVariance] {
        return query.apply(store.list())
    }
}
