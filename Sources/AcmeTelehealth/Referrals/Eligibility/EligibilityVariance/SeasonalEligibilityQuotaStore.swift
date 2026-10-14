import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps seasonal eligibility quotas by code.
    protocol SeasonalEligibilityQuotaStore {
        func find(_ code: String) -> SeasonalEligibilityQuota?
        func save(_ item: SeasonalEligibilityQuota)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalEligibilityQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalEligibilityQuotaStore: SeasonalEligibilityQuotaStore {
        var items: [String: SeasonalEligibilityQuota]
        var order: [String]

        init(items: [String: SeasonalEligibilityQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalEligibilityQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalEligibilityQuota) {
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

        func list() -> [SeasonalEligibilityQuota] {
            var out: [SeasonalEligibilityQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalEligibilityQuotaStore() -> any SeasonalEligibilityQuotaStore {
        return MemorySeasonalEligibilityQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalEligibilityQuotaStore: SeasonalEligibilityQuotaStore {
        var inner: MemorySeasonalEligibilityQuotaStore
        var cache: TTLCache<SeasonalEligibilityQuota>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalEligibilityQuotaStore, cache: TTLCache<SeasonalEligibilityQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalEligibilityQuota? {
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

        func save(_ item: SeasonalEligibilityQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalEligibilityQuota] {
            return inner.list()
        }
    }

    static func newCachedSeasonalEligibilityQuotaStore(_ inner: MemorySeasonalEligibilityQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalEligibilityQuotaStore {
        return CachedSeasonalEligibilityQuotaStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal eligibility quotas. Empty fields match all.
    final class SeasonalEligibilityQuotaQuery {
        var name: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalEligibilityQuota) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [SeasonalEligibilityQuota]) -> [SeasonalEligibilityQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalEligibilityQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalEligibilityQuotas(_ store: any SeasonalEligibilityQuotaStore, query: SeasonalEligibilityQuotaQuery) -> [SeasonalEligibilityQuota] {
        return query.apply(store.list())
    }
}
