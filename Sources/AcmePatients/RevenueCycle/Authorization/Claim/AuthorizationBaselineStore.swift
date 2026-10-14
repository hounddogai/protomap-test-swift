import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization baselines by code.
    protocol AuthorizationBaselineStore {
        func find(_ code: String) -> AuthorizationBaseline?
        func save(_ item: AuthorizationBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationBaselineStore: AuthorizationBaselineStore {
        var items: [String: AuthorizationBaseline]
        var order: [String]

        init(items: [String: AuthorizationBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationBaseline) {
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

        func list() -> [AuthorizationBaseline] {
            var out: [AuthorizationBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationBaselineStore() -> any AuthorizationBaselineStore {
        return MemoryAuthorizationBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationBaselineStore: AuthorizationBaselineStore {
        var inner: MemoryAuthorizationBaselineStore
        var cache: TTLCache<AuthorizationBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationBaselineStore, cache: TTLCache<AuthorizationBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationBaseline? {
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

        func save(_ item: AuthorizationBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationBaseline] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationBaselineStore(_ inner: MemoryAuthorizationBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationBaselineStore {
        return CachedAuthorizationBaselineStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization baselines. Empty fields match all.
    final class AuthorizationBaselineQuery {
        var label: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationBaseline) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationBaseline]) -> [AuthorizationBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationBaselines(_ store: any AuthorizationBaselineStore, query: AuthorizationBaselineQuery) -> [AuthorizationBaseline] {
        return query.apply(store.list())
    }
}
