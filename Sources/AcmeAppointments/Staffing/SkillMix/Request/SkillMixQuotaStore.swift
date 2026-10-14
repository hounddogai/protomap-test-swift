import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix quotas by code.
    protocol SkillMixQuotaStore {
        func find(_ code: String) -> SkillMixQuota?
        func save(_ item: SkillMixQuota)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixQuotaStore: SkillMixQuotaStore {
        var items: [String: SkillMixQuota]
        var order: [String]

        init(items: [String: SkillMixQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixQuota) {
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

        func list() -> [SkillMixQuota] {
            var out: [SkillMixQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixQuotaStore() -> any SkillMixQuotaStore {
        return MemorySkillMixQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixQuotaStore: SkillMixQuotaStore {
        var inner: MemorySkillMixQuotaStore
        var cache: TTLCache<SkillMixQuota>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixQuotaStore, cache: TTLCache<SkillMixQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixQuota? {
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

        func save(_ item: SkillMixQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixQuota] {
            return inner.list()
        }
    }

    static func newCachedSkillMixQuotaStore(_ inner: MemorySkillMixQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixQuotaStore {
        return CachedSkillMixQuotaStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix quotas. Empty fields match all.
    final class SkillMixQuotaQuery {
        var region: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixQuota) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixQuota]) -> [SkillMixQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixQuotas(_ store: any SkillMixQuotaStore, query: SkillMixQuotaQuery) -> [SkillMixQuota] {
        return query.apply(store.list())
    }
}
