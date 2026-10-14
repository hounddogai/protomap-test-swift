import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential requests by code.
    protocol CredentialRequestStore {
        func find(_ code: String) -> CredentialRequest?
        func save(_ item: CredentialRequest)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialRequestStore: CredentialRequestStore {
        var items: [String: CredentialRequest]
        var order: [String]

        init(items: [String: CredentialRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialRequest) {
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

        func list() -> [CredentialRequest] {
            var out: [CredentialRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialRequestStore() -> any CredentialRequestStore {
        return MemoryCredentialRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialRequestStore: CredentialRequestStore {
        var inner: MemoryCredentialRequestStore
        var cache: TTLCache<CredentialRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialRequestStore, cache: TTLCache<CredentialRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialRequest? {
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

        func save(_ item: CredentialRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialRequest] {
            return inner.list()
        }
    }

    static func newCachedCredentialRequestStore(_ inner: MemoryCredentialRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialRequestStore {
        return CachedCredentialRequestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential requests. Empty fields match all.
    final class CredentialRequestQuery {
        var country: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minBudget: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialRequest) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialRequest]) -> [CredentialRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialRequests(_ store: any CredentialRequestStore, query: CredentialRequestQuery) -> [CredentialRequest] {
        return query.apply(store.list())
    }
}
