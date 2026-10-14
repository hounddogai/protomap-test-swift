import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization agreements by code.
    protocol AuthorizationAgreementStore {
        func find(_ code: String) -> AuthorizationAgreement?
        func save(_ item: AuthorizationAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationAgreementStore: AuthorizationAgreementStore {
        var items: [String: AuthorizationAgreement]
        var order: [String]

        init(items: [String: AuthorizationAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationAgreement) {
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

        func list() -> [AuthorizationAgreement] {
            var out: [AuthorizationAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationAgreementStore() -> any AuthorizationAgreementStore {
        return MemoryAuthorizationAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationAgreementStore: AuthorizationAgreementStore {
        var inner: MemoryAuthorizationAgreementStore
        var cache: TTLCache<AuthorizationAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationAgreementStore, cache: TTLCache<AuthorizationAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationAgreement? {
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

        func save(_ item: AuthorizationAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationAgreement] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationAgreementStore(_ inner: MemoryAuthorizationAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationAgreementStore {
        return CachedAuthorizationAgreementStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization agreements. Empty fields match all.
    final class AuthorizationAgreementQuery {
        var country: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationAgreement) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationAgreement]) -> [AuthorizationAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationAgreements(_ store: any AuthorizationAgreementStore, query: AuthorizationAgreementQuery) -> [AuthorizationAgreement] {
        return query.apply(store.list())
    }
}
