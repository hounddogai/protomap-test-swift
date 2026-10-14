import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps rolling referral scores by code.
    protocol RollingReferralScoreStore {
        func find(_ code: String) -> RollingReferralScore?
        func save(_ item: RollingReferralScore)
        func remove(_ code: String) -> Bool
        func list() -> [RollingReferralScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingReferralScoreStore: RollingReferralScoreStore {
        var items: [String: RollingReferralScore]
        var order: [String]

        init(items: [String: RollingReferralScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingReferralScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingReferralScore) {
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

        func list() -> [RollingReferralScore] {
            var out: [RollingReferralScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingReferralScoreStore() -> any RollingReferralScoreStore {
        return MemoryRollingReferralScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingReferralScoreStore: RollingReferralScoreStore {
        var inner: MemoryRollingReferralScoreStore
        var cache: TTLCache<RollingReferralScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingReferralScoreStore, cache: TTLCache<RollingReferralScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingReferralScore? {
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

        func save(_ item: RollingReferralScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingReferralScore] {
            return inner.list()
        }
    }

    static func newCachedRollingReferralScoreStore(_ inner: MemoryRollingReferralScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingReferralScoreStore {
        return CachedRollingReferralScoreStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling referral scores. Empty fields match all.
    final class RollingReferralScoreQuery {
        var segment: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingReferralScore) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingReferralScore]) -> [RollingReferralScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingReferralScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingReferralScores(_ store: any RollingReferralScoreStore, query: RollingReferralScoreQuery) -> [RollingReferralScore] {
        return query.apply(store.list())
    }
}
