import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps adaptive network requests by code.
    protocol AdaptiveNetworkRequestStore {
        func find(_ code: String) -> AdaptiveNetworkRequest?
        func save(_ item: AdaptiveNetworkRequest)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveNetworkRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveNetworkRequestStore: AdaptiveNetworkRequestStore {
        var items: [String: AdaptiveNetworkRequest]
        var order: [String]

        init(items: [String: AdaptiveNetworkRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveNetworkRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveNetworkRequest) {
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

        func list() -> [AdaptiveNetworkRequest] {
            var out: [AdaptiveNetworkRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveNetworkRequestStore() -> any AdaptiveNetworkRequestStore {
        return MemoryAdaptiveNetworkRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveNetworkRequestStore: AdaptiveNetworkRequestStore {
        var inner: MemoryAdaptiveNetworkRequestStore
        var cache: TTLCache<AdaptiveNetworkRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveNetworkRequestStore, cache: TTLCache<AdaptiveNetworkRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveNetworkRequest? {
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

        func save(_ item: AdaptiveNetworkRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveNetworkRequest] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveNetworkRequestStore(_ inner: MemoryAdaptiveNetworkRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveNetworkRequestStore {
        return CachedAdaptiveNetworkRequestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive network requests. Empty fields match all.
    final class AdaptiveNetworkRequestQuery {
        var facility: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveNetworkRequest) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveNetworkRequest]) -> [AdaptiveNetworkRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveNetworkRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveNetworkRequests(_ store: any AdaptiveNetworkRequestStore, query: AdaptiveNetworkRequestQuery) -> [AdaptiveNetworkRequest] {
        return query.apply(store.list())
    }
}
