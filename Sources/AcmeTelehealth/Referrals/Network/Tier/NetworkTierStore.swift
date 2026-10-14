import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network tiers by code.
    protocol NetworkTierStore {
        func find(_ code: String) -> NetworkTier?
        func save(_ item: NetworkTier)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkTierStore: NetworkTierStore {
        var items: [String: NetworkTier]
        var order: [String]

        init(items: [String: NetworkTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkTier) {
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

        func list() -> [NetworkTier] {
            var out: [NetworkTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkTierStore() -> any NetworkTierStore {
        return MemoryNetworkTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkTierStore: NetworkTierStore {
        var inner: MemoryNetworkTierStore
        var cache: TTLCache<NetworkTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkTierStore, cache: TTLCache<NetworkTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkTier? {
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

        func save(_ item: NetworkTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkTier] {
            return inner.list()
        }
    }

    static func newCachedNetworkTierStore(_ inner: MemoryNetworkTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkTierStore {
        return CachedNetworkTierStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network tiers. Empty fields match all.
    final class NetworkTierQuery {
        var title: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRatio: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkTier) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [NetworkTier]) -> [NetworkTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkTiers(_ store: any NetworkTierStore, query: NetworkTierQuery) -> [NetworkTier] {
        return query.apply(store.list())
    }
}
