import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network groups by code.
    protocol NetworkGroupStore {
        func find(_ code: String) -> NetworkGroup?
        func save(_ item: NetworkGroup)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkGroupStore: NetworkGroupStore {
        var items: [String: NetworkGroup]
        var order: [String]

        init(items: [String: NetworkGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkGroup) {
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

        func list() -> [NetworkGroup] {
            var out: [NetworkGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkGroupStore() -> any NetworkGroupStore {
        return MemoryNetworkGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkGroupStore: NetworkGroupStore {
        var inner: MemoryNetworkGroupStore
        var cache: TTLCache<NetworkGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkGroupStore, cache: TTLCache<NetworkGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkGroup? {
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

        func save(_ item: NetworkGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkGroup] {
            return inner.list()
        }
    }

    static func newCachedNetworkGroupStore(_ inner: MemoryNetworkGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkGroupStore {
        return CachedNetworkGroupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network groups. Empty fields match all.
    final class NetworkGroupQuery {
        var segment: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minCopay: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkGroup) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [NetworkGroup]) -> [NetworkGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkGroups(_ store: any NetworkGroupStore, query: NetworkGroupQuery) -> [NetworkGroup] {
        return query.apply(store.list())
    }
}
