import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps fallback referral audits by code.
    protocol FallbackReferralAuditStore {
        func find(_ code: String) -> FallbackReferralAudit?
        func save(_ item: FallbackReferralAudit)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackReferralAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackReferralAuditStore: FallbackReferralAuditStore {
        var items: [String: FallbackReferralAudit]
        var order: [String]

        init(items: [String: FallbackReferralAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackReferralAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackReferralAudit) {
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

        func list() -> [FallbackReferralAudit] {
            var out: [FallbackReferralAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackReferralAuditStore() -> any FallbackReferralAuditStore {
        return MemoryFallbackReferralAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackReferralAuditStore: FallbackReferralAuditStore {
        var inner: MemoryFallbackReferralAuditStore
        var cache: TTLCache<FallbackReferralAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackReferralAuditStore, cache: TTLCache<FallbackReferralAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackReferralAudit? {
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

        func save(_ item: FallbackReferralAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackReferralAudit] {
            return inner.list()
        }
    }

    static func newCachedFallbackReferralAuditStore(_ inner: MemoryFallbackReferralAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackReferralAuditStore {
        return CachedFallbackReferralAuditStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback referral audits. Empty fields match all.
    final class FallbackReferralAuditQuery {
        var country: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minMargin: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackReferralAudit) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackReferralAudit]) -> [FallbackReferralAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackReferralAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackReferralAudits(_ store: any FallbackReferralAuditStore, query: FallbackReferralAuditQuery) -> [FallbackReferralAudit] {
        return query.apply(store.list())
    }
}
