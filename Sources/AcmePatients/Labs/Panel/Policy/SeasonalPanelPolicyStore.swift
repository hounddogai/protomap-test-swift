import AcmePlatform
import Foundation

extension Labs {
    /// Keeps seasonal panel policies by code.
    protocol SeasonalPanelPolicyStore {
        func find(_ code: String) -> SeasonalPanelPolicy?
        func save(_ item: SeasonalPanelPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalPanelPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalPanelPolicyStore: SeasonalPanelPolicyStore {
        var items: [String: SeasonalPanelPolicy]
        var order: [String]

        init(items: [String: SeasonalPanelPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalPanelPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalPanelPolicy) {
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

        func list() -> [SeasonalPanelPolicy] {
            var out: [SeasonalPanelPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalPanelPolicyStore() -> any SeasonalPanelPolicyStore {
        return MemorySeasonalPanelPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalPanelPolicyStore: SeasonalPanelPolicyStore {
        var inner: MemorySeasonalPanelPolicyStore
        var cache: TTLCache<SeasonalPanelPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalPanelPolicyStore, cache: TTLCache<SeasonalPanelPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalPanelPolicy? {
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

        func save(_ item: SeasonalPanelPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalPanelPolicy] {
            return inner.list()
        }
    }

    static func newCachedSeasonalPanelPolicyStore(_ inner: MemorySeasonalPanelPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalPanelPolicyStore {
        return CachedSeasonalPanelPolicyStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal panel policies. Empty fields match all.
    final class SeasonalPanelPolicyQuery {
        var country: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalPanelPolicy) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalPanelPolicy]) -> [SeasonalPanelPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalPanelPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalPanelPolicies(_ store: any SeasonalPanelPolicyStore, query: SeasonalPanelPolicyQuery) -> [SeasonalPanelPolicy] {
        return query.apply(store.list())
    }
}
