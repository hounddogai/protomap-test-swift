import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral audits by code.
    protocol ReferralAuditStore {
        func find(_ code: String) -> ReferralAudit?
        func save(_ item: ReferralAudit)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralAuditStore: ReferralAuditStore {
        var items: [String: ReferralAudit]
        var order: [String]

        init(items: [String: ReferralAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralAudit) {
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

        func list() -> [ReferralAudit] {
            var out: [ReferralAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralAuditStore() -> any ReferralAuditStore {
        return MemoryReferralAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralAuditStore: ReferralAuditStore {
        var inner: MemoryReferralAuditStore
        var cache: TTLCache<ReferralAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralAuditStore, cache: TTLCache<ReferralAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralAudit? {
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

        func save(_ item: ReferralAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralAudit] {
            return inner.list()
        }
    }

    static func newCachedReferralAuditStore(_ inner: MemoryReferralAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralAuditStore {
        return CachedReferralAuditStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral audits. Empty fields match all.
    final class ReferralAuditQuery {
        var channel: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minVersion: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralAudit) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferralAudit]) -> [ReferralAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralAudits(_ store: any ReferralAuditStore, query: ReferralAuditQuery) -> [ReferralAudit] {
        return query.apply(store.list())
    }
}
