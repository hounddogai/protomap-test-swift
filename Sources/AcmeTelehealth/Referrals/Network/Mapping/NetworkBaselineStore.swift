import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network baselines by code.
    protocol NetworkBaselineStore {
        func find(_ code: String) -> NetworkBaseline?
        func save(_ item: NetworkBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkBaselineStore: NetworkBaselineStore {
        var items: [String: NetworkBaseline]
        var order: [String]

        init(items: [String: NetworkBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkBaseline) {
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

        func list() -> [NetworkBaseline] {
            var out: [NetworkBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkBaselineStore() -> any NetworkBaselineStore {
        return MemoryNetworkBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkBaselineStore: NetworkBaselineStore {
        var inner: MemoryNetworkBaselineStore
        var cache: TTLCache<NetworkBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkBaselineStore, cache: TTLCache<NetworkBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkBaseline? {
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

        func save(_ item: NetworkBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkBaseline] {
            return inner.list()
        }
    }

    static func newCachedNetworkBaselineStore(_ inner: MemoryNetworkBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkBaselineStore {
        return CachedNetworkBaselineStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network baselines. Empty fields match all.
    final class NetworkBaselineQuery {
        var unit: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minCost: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkBaseline) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [NetworkBaseline]) -> [NetworkBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkBaselines(_ store: any NetworkBaselineStore, query: NetworkBaselineQuery) -> [NetworkBaseline] {
        return query.apply(store.list())
    }
}
