import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization requests by code.
    protocol AuthorizationRequestStore {
        func find(_ code: String) -> AuthorizationRequest?
        func save(_ item: AuthorizationRequest)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationRequestStore: AuthorizationRequestStore {
        var items: [String: AuthorizationRequest]
        var order: [String]

        init(items: [String: AuthorizationRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationRequest) {
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

        func list() -> [AuthorizationRequest] {
            var out: [AuthorizationRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationRequestStore() -> any AuthorizationRequestStore {
        return MemoryAuthorizationRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationRequestStore: AuthorizationRequestStore {
        var inner: MemoryAuthorizationRequestStore
        var cache: TTLCache<AuthorizationRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationRequestStore, cache: TTLCache<AuthorizationRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationRequest? {
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

        func save(_ item: AuthorizationRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationRequest] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationRequestStore(_ inner: MemoryAuthorizationRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationRequestStore {
        return CachedAuthorizationRequestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization requests. Empty fields match all.
    final class AuthorizationRequestQuery {
        var label: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minWeight: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationRequest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [AuthorizationRequest]) -> [AuthorizationRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationRequests(_ store: any AuthorizationRequestStore, query: AuthorizationRequestQuery) -> [AuthorizationRequest] {
        return query.apply(store.list())
    }
}
