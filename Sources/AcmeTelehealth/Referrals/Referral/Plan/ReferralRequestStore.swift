import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral requests by code.
    protocol ReferralRequestStore {
        func find(_ code: String) -> ReferralRequest?
        func save(_ item: ReferralRequest)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralRequestStore: ReferralRequestStore {
        var items: [String: ReferralRequest]
        var order: [String]

        init(items: [String: ReferralRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralRequest) {
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

        func list() -> [ReferralRequest] {
            var out: [ReferralRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralRequestStore() -> any ReferralRequestStore {
        return MemoryReferralRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralRequestStore: ReferralRequestStore {
        var inner: MemoryReferralRequestStore
        var cache: TTLCache<ReferralRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralRequestStore, cache: TTLCache<ReferralRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralRequest? {
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

        func save(_ item: ReferralRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralRequest] {
            return inner.list()
        }
    }

    static func newCachedReferralRequestStore(_ inner: MemoryReferralRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralRequestStore {
        return CachedReferralRequestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral requests. Empty fields match all.
    final class ReferralRequestQuery {
        var name: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralRequest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [ReferralRequest]) -> [ReferralRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralRequests(_ store: any ReferralRequestStore, query: ReferralRequestQuery) -> [ReferralRequest] {
        return query.apply(store.list())
    }
}
