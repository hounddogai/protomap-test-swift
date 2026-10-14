import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps seasonal referral audits by code.
    protocol SeasonalReferralAuditStore {
        func find(_ code: String) -> SeasonalReferralAudit?
        func save(_ item: SeasonalReferralAudit)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalReferralAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalReferralAuditStore: SeasonalReferralAuditStore {
        var items: [String: SeasonalReferralAudit]
        var order: [String]

        init(items: [String: SeasonalReferralAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalReferralAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalReferralAudit) {
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

        func list() -> [SeasonalReferralAudit] {
            var out: [SeasonalReferralAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalReferralAuditStore() -> any SeasonalReferralAuditStore {
        return MemorySeasonalReferralAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalReferralAuditStore: SeasonalReferralAuditStore {
        var inner: MemorySeasonalReferralAuditStore
        var cache: TTLCache<SeasonalReferralAudit>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalReferralAuditStore, cache: TTLCache<SeasonalReferralAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalReferralAudit? {
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

        func save(_ item: SeasonalReferralAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalReferralAudit] {
            return inner.list()
        }
    }

    static func newCachedSeasonalReferralAuditStore(_ inner: MemorySeasonalReferralAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalReferralAuditStore {
        return CachedSeasonalReferralAuditStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal referral audits. Empty fields match all.
    final class SeasonalReferralAuditQuery {
        var unit: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minScore: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalReferralAudit) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalReferralAudit]) -> [SeasonalReferralAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalReferralAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalReferralAudits(_ store: any SeasonalReferralAuditStore, query: SeasonalReferralAuditQuery) -> [SeasonalReferralAudit] {
        return query.apply(store.list())
    }
}
