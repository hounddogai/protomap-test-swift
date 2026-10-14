import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization scores by code.
    protocol AuthorizationScoreStore {
        func find(_ code: String) -> AuthorizationScore?
        func save(_ item: AuthorizationScore)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationScoreStore: AuthorizationScoreStore {
        var items: [String: AuthorizationScore]
        var order: [String]

        init(items: [String: AuthorizationScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationScore) {
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

        func list() -> [AuthorizationScore] {
            var out: [AuthorizationScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationScoreStore() -> any AuthorizationScoreStore {
        return MemoryAuthorizationScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationScoreStore: AuthorizationScoreStore {
        var inner: MemoryAuthorizationScoreStore
        var cache: TTLCache<AuthorizationScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationScoreStore, cache: TTLCache<AuthorizationScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationScore? {
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

        func save(_ item: AuthorizationScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationScore] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationScoreStore(_ inner: MemoryAuthorizationScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationScoreStore {
        return CachedAuthorizationScoreStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization scores. Empty fields match all.
    final class AuthorizationScoreQuery {
        var title: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationScore) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationScore]) -> [AuthorizationScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationScores(_ store: any AuthorizationScoreStore, query: AuthorizationScoreQuery) -> [AuthorizationScore] {
        return query.apply(store.list())
    }
}
