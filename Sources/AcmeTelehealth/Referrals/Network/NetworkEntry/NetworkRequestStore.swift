import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network requests by code.
    protocol NetworkRequestStore {
        func find(_ code: String) -> NetworkRequest?
        func save(_ item: NetworkRequest)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkRequestStore: NetworkRequestStore {
        var items: [String: NetworkRequest]
        var order: [String]

        init(items: [String: NetworkRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkRequest) {
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

        func list() -> [NetworkRequest] {
            var out: [NetworkRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkRequestStore() -> any NetworkRequestStore {
        return MemoryNetworkRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkRequestStore: NetworkRequestStore {
        var inner: MemoryNetworkRequestStore
        var cache: TTLCache<NetworkRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkRequestStore, cache: TTLCache<NetworkRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkRequest? {
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

        func save(_ item: NetworkRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkRequest] {
            return inner.list()
        }
    }

    static func newCachedNetworkRequestStore(_ inner: MemoryNetworkRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkRequestStore {
        return CachedNetworkRequestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network requests. Empty fields match all.
    final class NetworkRequestQuery {
        var label: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkRequest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [NetworkRequest]) -> [NetworkRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkRequests(_ store: any NetworkRequestStore, query: NetworkRequestQuery) -> [NetworkRequest] {
        return query.apply(store.list())
    }
}
