import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps weighted authorization requests by code.
    protocol WeightedAuthorizationRequestStore {
        func find(_ code: String) -> WeightedAuthorizationRequest?
        func save(_ item: WeightedAuthorizationRequest)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedAuthorizationRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedAuthorizationRequestStore: WeightedAuthorizationRequestStore {
        var items: [String: WeightedAuthorizationRequest]
        var order: [String]

        init(items: [String: WeightedAuthorizationRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedAuthorizationRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedAuthorizationRequest) {
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

        func list() -> [WeightedAuthorizationRequest] {
            var out: [WeightedAuthorizationRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedAuthorizationRequestStore() -> any WeightedAuthorizationRequestStore {
        return MemoryWeightedAuthorizationRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedAuthorizationRequestStore: WeightedAuthorizationRequestStore {
        var inner: MemoryWeightedAuthorizationRequestStore
        var cache: TTLCache<WeightedAuthorizationRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedAuthorizationRequestStore, cache: TTLCache<WeightedAuthorizationRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedAuthorizationRequest? {
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

        func save(_ item: WeightedAuthorizationRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedAuthorizationRequest] {
            return inner.list()
        }
    }

    static func newCachedWeightedAuthorizationRequestStore(_ inner: MemoryWeightedAuthorizationRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedAuthorizationRequestStore {
        return CachedWeightedAuthorizationRequestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted authorization requests. Empty fields match all.
    final class WeightedAuthorizationRequestQuery {
        var category: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedAuthorizationRequest) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedAuthorizationRequest]) -> [WeightedAuthorizationRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedAuthorizationRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedAuthorizationRequests(_ store: any WeightedAuthorizationRequestStore, query: WeightedAuthorizationRequestQuery) -> [WeightedAuthorizationRequest] {
        return query.apply(store.list())
    }
}
