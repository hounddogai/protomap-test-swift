import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps regional skill mix quotas by code.
    protocol RegionalSkillMixQuotaStore {
        func find(_ code: String) -> RegionalSkillMixQuota?
        func save(_ item: RegionalSkillMixQuota)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalSkillMixQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalSkillMixQuotaStore: RegionalSkillMixQuotaStore {
        var items: [String: RegionalSkillMixQuota]
        var order: [String]

        init(items: [String: RegionalSkillMixQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalSkillMixQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalSkillMixQuota) {
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

        func list() -> [RegionalSkillMixQuota] {
            var out: [RegionalSkillMixQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalSkillMixQuotaStore() -> any RegionalSkillMixQuotaStore {
        return MemoryRegionalSkillMixQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalSkillMixQuotaStore: RegionalSkillMixQuotaStore {
        var inner: MemoryRegionalSkillMixQuotaStore
        var cache: TTLCache<RegionalSkillMixQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalSkillMixQuotaStore, cache: TTLCache<RegionalSkillMixQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalSkillMixQuota? {
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

        func save(_ item: RegionalSkillMixQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalSkillMixQuota] {
            return inner.list()
        }
    }

    static func newCachedRegionalSkillMixQuotaStore(_ inner: MemoryRegionalSkillMixQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalSkillMixQuotaStore {
        return CachedRegionalSkillMixQuotaStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional skill mix quotas. Empty fields match all.
    final class RegionalSkillMixQuotaQuery {
        var country: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minCopay: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalSkillMixQuota) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalSkillMixQuota]) -> [RegionalSkillMixQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalSkillMixQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalSkillMixQuotas(_ store: any RegionalSkillMixQuotaStore, query: RegionalSkillMixQuotaQuery) -> [RegionalSkillMixQuota] {
        return query.apply(store.list())
    }
}
