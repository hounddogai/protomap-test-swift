import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility quotas by code.
    protocol EligibilityQuotaStore {
        func find(_ code: String) -> EligibilityQuota?
        func save(_ item: EligibilityQuota)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityQuotaStore: EligibilityQuotaStore {
        var items: [String: EligibilityQuota]
        var order: [String]

        init(items: [String: EligibilityQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityQuota) {
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

        func list() -> [EligibilityQuota] {
            var out: [EligibilityQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityQuotaStore() -> any EligibilityQuotaStore {
        return MemoryEligibilityQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityQuotaStore: EligibilityQuotaStore {
        var inner: MemoryEligibilityQuotaStore
        var cache: TTLCache<EligibilityQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityQuotaStore, cache: TTLCache<EligibilityQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityQuota? {
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

        func save(_ item: EligibilityQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityQuota] {
            return inner.list()
        }
    }

    static func newCachedEligibilityQuotaStore(_ inner: MemoryEligibilityQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityQuotaStore {
        return CachedEligibilityQuotaStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility quotas. Empty fields match all.
    final class EligibilityQuotaQuery {
        var label: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilityQuota) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [EligibilityQuota]) -> [EligibilityQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityQuotas(_ store: any EligibilityQuotaStore, query: EligibilityQuotaQuery) -> [EligibilityQuota] {
        return query.apply(store.list())
    }
}
