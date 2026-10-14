import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps seasonal read plans by code.
    protocol SeasonalReadPlanStore {
        func find(_ code: String) -> SeasonalReadPlan?
        func save(_ item: SeasonalReadPlan)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalReadPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalReadPlanStore: SeasonalReadPlanStore {
        var items: [String: SeasonalReadPlan]
        var order: [String]

        init(items: [String: SeasonalReadPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalReadPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalReadPlan) {
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

        func list() -> [SeasonalReadPlan] {
            var out: [SeasonalReadPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalReadPlanStore() -> any SeasonalReadPlanStore {
        return MemorySeasonalReadPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalReadPlanStore: SeasonalReadPlanStore {
        var inner: MemorySeasonalReadPlanStore
        var cache: TTLCache<SeasonalReadPlan>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalReadPlanStore, cache: TTLCache<SeasonalReadPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalReadPlan? {
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

        func save(_ item: SeasonalReadPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalReadPlan] {
            return inner.list()
        }
    }

    static func newCachedSeasonalReadPlanStore(_ inner: MemorySeasonalReadPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalReadPlanStore {
        return CachedSeasonalReadPlanStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal read plans. Empty fields match all.
    final class SeasonalReadPlanQuery {
        var country: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalReadPlan) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalReadPlan]) -> [SeasonalReadPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalReadPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalReadPlans(_ store: any SeasonalReadPlanStore, query: SeasonalReadPlanQuery) -> [SeasonalReadPlan] {
        return query.apply(store.list())
    }
}
