import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network claims by code.
    protocol NetworkClaimStore {
        func find(_ code: String) -> NetworkClaim?
        func save(_ item: NetworkClaim)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkClaimStore: NetworkClaimStore {
        var items: [String: NetworkClaim]
        var order: [String]

        init(items: [String: NetworkClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkClaim) {
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

        func list() -> [NetworkClaim] {
            var out: [NetworkClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkClaimStore() -> any NetworkClaimStore {
        return MemoryNetworkClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkClaimStore: NetworkClaimStore {
        var inner: MemoryNetworkClaimStore
        var cache: TTLCache<NetworkClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkClaimStore, cache: TTLCache<NetworkClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkClaim? {
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

        func save(_ item: NetworkClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkClaim] {
            return inner.list()
        }
    }

    static func newCachedNetworkClaimStore(_ inner: MemoryNetworkClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkClaimStore {
        return CachedNetworkClaimStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network claims. Empty fields match all.
    final class NetworkClaimQuery {
        var title: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkClaim) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [NetworkClaim]) -> [NetworkClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkClaims(_ store: any NetworkClaimStore, query: NetworkClaimQuery) -> [NetworkClaim] {
        return query.apply(store.list())
    }
}
