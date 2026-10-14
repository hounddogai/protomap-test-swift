import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps global referral overrides by code.
    protocol GlobalReferralOverrideStore {
        func find(_ code: String) -> GlobalReferralOverride?
        func save(_ item: GlobalReferralOverride)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalReferralOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalReferralOverrideStore: GlobalReferralOverrideStore {
        var items: [String: GlobalReferralOverride]
        var order: [String]

        init(items: [String: GlobalReferralOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalReferralOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalReferralOverride) {
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

        func list() -> [GlobalReferralOverride] {
            var out: [GlobalReferralOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalReferralOverrideStore() -> any GlobalReferralOverrideStore {
        return MemoryGlobalReferralOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalReferralOverrideStore: GlobalReferralOverrideStore {
        var inner: MemoryGlobalReferralOverrideStore
        var cache: TTLCache<GlobalReferralOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalReferralOverrideStore, cache: TTLCache<GlobalReferralOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalReferralOverride? {
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

        func save(_ item: GlobalReferralOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalReferralOverride] {
            return inner.list()
        }
    }

    static func newCachedGlobalReferralOverrideStore(_ inner: MemoryGlobalReferralOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalReferralOverrideStore {
        return CachedGlobalReferralOverrideStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global referral overrides. Empty fields match all.
    final class GlobalReferralOverrideQuery {
        var channel: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalReferralOverride) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalReferralOverride]) -> [GlobalReferralOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalReferralOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalReferralOverrides(_ store: any GlobalReferralOverrideStore, query: GlobalReferralOverrideQuery) -> [GlobalReferralOverride] {
        return query.apply(store.list())
    }
}
