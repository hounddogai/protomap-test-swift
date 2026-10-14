import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps regional remittance variances by code.
    protocol RegionalRemittanceVarianceStore {
        func find(_ code: String) -> RegionalRemittanceVariance?
        func save(_ item: RegionalRemittanceVariance)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalRemittanceVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalRemittanceVarianceStore: RegionalRemittanceVarianceStore {
        var items: [String: RegionalRemittanceVariance]
        var order: [String]

        init(items: [String: RegionalRemittanceVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalRemittanceVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalRemittanceVariance) {
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

        func list() -> [RegionalRemittanceVariance] {
            var out: [RegionalRemittanceVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalRemittanceVarianceStore() -> any RegionalRemittanceVarianceStore {
        return MemoryRegionalRemittanceVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalRemittanceVarianceStore: RegionalRemittanceVarianceStore {
        var inner: MemoryRegionalRemittanceVarianceStore
        var cache: TTLCache<RegionalRemittanceVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalRemittanceVarianceStore, cache: TTLCache<RegionalRemittanceVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalRemittanceVariance? {
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

        func save(_ item: RegionalRemittanceVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalRemittanceVariance] {
            return inner.list()
        }
    }

    static func newCachedRegionalRemittanceVarianceStore(_ inner: MemoryRegionalRemittanceVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalRemittanceVarianceStore {
        return CachedRegionalRemittanceVarianceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional remittance variances. Empty fields match all.
    final class RegionalRemittanceVarianceQuery {
        var source: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalRemittanceVariance) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalRemittanceVariance]) -> [RegionalRemittanceVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalRemittanceVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalRemittanceVariances(_ store: any RegionalRemittanceVarianceStore, query: RegionalRemittanceVarianceQuery) -> [RegionalRemittanceVariance] {
        return query.apply(store.list())
    }
}
