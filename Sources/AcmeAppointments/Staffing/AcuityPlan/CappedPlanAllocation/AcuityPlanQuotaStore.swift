import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan quotas by code.
    protocol AcuityPlanQuotaStore {
        func find(_ code: String) -> AcuityPlanQuota?
        func save(_ item: AcuityPlanQuota)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanQuotaStore: AcuityPlanQuotaStore {
        var items: [String: AcuityPlanQuota]
        var order: [String]

        init(items: [String: AcuityPlanQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanQuota) {
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

        func list() -> [AcuityPlanQuota] {
            var out: [AcuityPlanQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanQuotaStore() -> any AcuityPlanQuotaStore {
        return MemoryAcuityPlanQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanQuotaStore: AcuityPlanQuotaStore {
        var inner: MemoryAcuityPlanQuotaStore
        var cache: TTLCache<AcuityPlanQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanQuotaStore, cache: TTLCache<AcuityPlanQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanQuota? {
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

        func save(_ item: AcuityPlanQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanQuota] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanQuotaStore(_ inner: MemoryAcuityPlanQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanQuotaStore {
        return CachedAcuityPlanQuotaStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan quotas. Empty fields match all.
    final class AcuityPlanQuotaQuery {
        var source: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanQuota) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AcuityPlanQuota]) -> [AcuityPlanQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanQuotas(_ store: any AcuityPlanQuotaStore, query: AcuityPlanQuotaQuery) -> [AcuityPlanQuota] {
        return query.apply(store.list())
    }
}
