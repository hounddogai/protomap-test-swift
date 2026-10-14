import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network targets by code.
    protocol NetworkTargetStore {
        func find(_ code: String) -> NetworkTarget?
        func save(_ item: NetworkTarget)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkTargetStore: NetworkTargetStore {
        var items: [String: NetworkTarget]
        var order: [String]

        init(items: [String: NetworkTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkTarget) {
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

        func list() -> [NetworkTarget] {
            var out: [NetworkTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkTargetStore() -> any NetworkTargetStore {
        return MemoryNetworkTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkTargetStore: NetworkTargetStore {
        var inner: MemoryNetworkTargetStore
        var cache: TTLCache<NetworkTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkTargetStore, cache: TTLCache<NetworkTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkTarget? {
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

        func save(_ item: NetworkTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkTarget] {
            return inner.list()
        }
    }

    static func newCachedNetworkTargetStore(_ inner: MemoryNetworkTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkTargetStore {
        return CachedNetworkTargetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network targets. Empty fields match all.
    final class NetworkTargetQuery {
        var name: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMargin: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkTarget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [NetworkTarget]) -> [NetworkTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkTargets(_ store: any NetworkTargetStore, query: NetworkTargetQuery) -> [NetworkTarget] {
        return query.apply(store.list())
    }
}
