import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network rollups by code.
    protocol NetworkRollupStore {
        func find(_ code: String) -> NetworkRollup?
        func save(_ item: NetworkRollup)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkRollupStore: NetworkRollupStore {
        var items: [String: NetworkRollup]
        var order: [String]

        init(items: [String: NetworkRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkRollup) {
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

        func list() -> [NetworkRollup] {
            var out: [NetworkRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkRollupStore() -> any NetworkRollupStore {
        return MemoryNetworkRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkRollupStore: NetworkRollupStore {
        var inner: MemoryNetworkRollupStore
        var cache: TTLCache<NetworkRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkRollupStore, cache: TTLCache<NetworkRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkRollup? {
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

        func save(_ item: NetworkRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkRollup] {
            return inner.list()
        }
    }

    static func newCachedNetworkRollupStore(_ inner: MemoryNetworkRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkRollupStore {
        return CachedNetworkRollupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network rollups. Empty fields match all.
    final class NetworkRollupQuery {
        var region: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minWeight: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkRollup) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [NetworkRollup]) -> [NetworkRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkRollups(_ store: any NetworkRollupStore, query: NetworkRollupQuery) -> [NetworkRollup] {
        return query.apply(store.list())
    }
}
