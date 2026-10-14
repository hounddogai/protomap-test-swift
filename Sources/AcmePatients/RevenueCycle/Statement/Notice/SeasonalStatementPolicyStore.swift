import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps seasonal statement policies by code.
    protocol SeasonalStatementPolicyStore {
        func find(_ code: String) -> SeasonalStatementPolicy?
        func save(_ item: SeasonalStatementPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalStatementPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalStatementPolicyStore: SeasonalStatementPolicyStore {
        var items: [String: SeasonalStatementPolicy]
        var order: [String]

        init(items: [String: SeasonalStatementPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalStatementPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalStatementPolicy) {
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

        func list() -> [SeasonalStatementPolicy] {
            var out: [SeasonalStatementPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalStatementPolicyStore() -> any SeasonalStatementPolicyStore {
        return MemorySeasonalStatementPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalStatementPolicyStore: SeasonalStatementPolicyStore {
        var inner: MemorySeasonalStatementPolicyStore
        var cache: TTLCache<SeasonalStatementPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalStatementPolicyStore, cache: TTLCache<SeasonalStatementPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalStatementPolicy? {
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

        func save(_ item: SeasonalStatementPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalStatementPolicy] {
            return inner.list()
        }
    }

    static func newCachedSeasonalStatementPolicyStore(_ inner: MemorySeasonalStatementPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalStatementPolicyStore {
        return CachedSeasonalStatementPolicyStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal statement policies. Empty fields match all.
    final class SeasonalStatementPolicyQuery {
        var segment: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minRefills: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalStatementPolicy) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalStatementPolicy]) -> [SeasonalStatementPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalStatementPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalStatementPolicies(_ store: any SeasonalStatementPolicyStore, query: SeasonalStatementPolicyQuery) -> [SeasonalStatementPolicy] {
        return query.apply(store.list())
    }
}
