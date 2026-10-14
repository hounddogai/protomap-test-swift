import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap quotas by code.
    protocol CareGapQuotaStore {
        func find(_ code: String) -> CareGapQuota?
        func save(_ item: CareGapQuota)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapQuotaStore: CareGapQuotaStore {
        var items: [String: CareGapQuota]
        var order: [String]

        init(items: [String: CareGapQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapQuota) {
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

        func list() -> [CareGapQuota] {
            var out: [CareGapQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapQuotaStore() -> any CareGapQuotaStore {
        return MemoryCareGapQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapQuotaStore: CareGapQuotaStore {
        var inner: MemoryCareGapQuotaStore
        var cache: TTLCache<CareGapQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapQuotaStore, cache: TTLCache<CareGapQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapQuota? {
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

        func save(_ item: CareGapQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapQuota] {
            return inner.list()
        }
    }

    static func newCachedCareGapQuotaStore(_ inner: MemoryCareGapQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapQuotaStore {
        return CachedCareGapQuotaStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap quotas. Empty fields match all.
    final class CareGapQuotaQuery {
        var country: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapQuota) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [CareGapQuota]) -> [CareGapQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapQuotas(_ store: any CareGapQuotaStore, query: CareGapQuotaQuery) -> [CareGapQuota] {
        return query.apply(store.list())
    }
}
