import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps primary network tiers by code.
    protocol PrimaryNetworkTierStore {
        func find(_ code: String) -> PrimaryNetworkTier?
        func save(_ item: PrimaryNetworkTier)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryNetworkTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryNetworkTierStore: PrimaryNetworkTierStore {
        var items: [String: PrimaryNetworkTier]
        var order: [String]

        init(items: [String: PrimaryNetworkTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryNetworkTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryNetworkTier) {
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

        func list() -> [PrimaryNetworkTier] {
            var out: [PrimaryNetworkTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryNetworkTierStore() -> any PrimaryNetworkTierStore {
        return MemoryPrimaryNetworkTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryNetworkTierStore: PrimaryNetworkTierStore {
        var inner: MemoryPrimaryNetworkTierStore
        var cache: TTLCache<PrimaryNetworkTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryNetworkTierStore, cache: TTLCache<PrimaryNetworkTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryNetworkTier? {
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

        func save(_ item: PrimaryNetworkTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryNetworkTier] {
            return inner.list()
        }
    }

    static func newCachedPrimaryNetworkTierStore(_ inner: MemoryPrimaryNetworkTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryNetworkTierStore {
        return CachedPrimaryNetworkTierStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary network tiers. Empty fields match all.
    final class PrimaryNetworkTierQuery {
        var name: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minPriority: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryNetworkTier) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryNetworkTier]) -> [PrimaryNetworkTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryNetworkTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryNetworkTiers(_ store: any PrimaryNetworkTierStore, query: PrimaryNetworkTierQuery) -> [PrimaryNetworkTier] {
        return query.apply(store.list())
    }
}
