import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization summaries by code.
    protocol AuthorizationSummaryStore {
        func find(_ code: String) -> AuthorizationSummary?
        func save(_ item: AuthorizationSummary)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationSummaryStore: AuthorizationSummaryStore {
        var items: [String: AuthorizationSummary]
        var order: [String]

        init(items: [String: AuthorizationSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationSummary) {
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

        func list() -> [AuthorizationSummary] {
            var out: [AuthorizationSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationSummaryStore() -> any AuthorizationSummaryStore {
        return MemoryAuthorizationSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationSummaryStore: AuthorizationSummaryStore {
        var inner: MemoryAuthorizationSummaryStore
        var cache: TTLCache<AuthorizationSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationSummaryStore, cache: TTLCache<AuthorizationSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationSummary? {
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

        func save(_ item: AuthorizationSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationSummary] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationSummaryStore(_ inner: MemoryAuthorizationSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationSummaryStore {
        return CachedAuthorizationSummaryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization summaries. Empty fields match all.
    final class AuthorizationSummaryQuery {
        var facility: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationSummary) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationSummary]) -> [AuthorizationSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationSummaries(_ store: any AuthorizationSummaryStore, query: AuthorizationSummaryQuery) -> [AuthorizationSummary] {
        return query.apply(store.list())
    }
}
