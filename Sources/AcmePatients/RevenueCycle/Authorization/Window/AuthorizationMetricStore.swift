import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization metrics by code.
    protocol AuthorizationMetricStore {
        func find(_ code: String) -> AuthorizationMetric?
        func save(_ item: AuthorizationMetric)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationMetricStore: AuthorizationMetricStore {
        var items: [String: AuthorizationMetric]
        var order: [String]

        init(items: [String: AuthorizationMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationMetric) {
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

        func list() -> [AuthorizationMetric] {
            var out: [AuthorizationMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationMetricStore() -> any AuthorizationMetricStore {
        return MemoryAuthorizationMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationMetricStore: AuthorizationMetricStore {
        var inner: MemoryAuthorizationMetricStore
        var cache: TTLCache<AuthorizationMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationMetricStore, cache: TTLCache<AuthorizationMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationMetric? {
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

        func save(_ item: AuthorizationMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationMetric] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationMetricStore(_ inner: MemoryAuthorizationMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationMetricStore {
        return CachedAuthorizationMetricStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization metrics. Empty fields match all.
    final class AuthorizationMetricQuery {
        var category: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minRevision: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationMetric) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationMetric]) -> [AuthorizationMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationMetrics(_ store: any AuthorizationMetricStore, query: AuthorizationMetricQuery) -> [AuthorizationMetric] {
        return query.apply(store.list())
    }
}
