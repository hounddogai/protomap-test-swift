import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial plans by code.
    protocol DenialPlanStore {
        func find(_ code: String) -> DenialPlan?
        func save(_ item: DenialPlan)
        func remove(_ code: String) -> Bool
        func list() -> [DenialPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialPlanStore: DenialPlanStore {
        var items: [String: DenialPlan]
        var order: [String]

        init(items: [String: DenialPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialPlan) {
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

        func list() -> [DenialPlan] {
            var out: [DenialPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialPlanStore() -> any DenialPlanStore {
        return MemoryDenialPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialPlanStore: DenialPlanStore {
        var inner: MemoryDenialPlanStore
        var cache: TTLCache<DenialPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialPlanStore, cache: TTLCache<DenialPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialPlan? {
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

        func save(_ item: DenialPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialPlan] {
            return inner.list()
        }
    }

    static func newCachedDenialPlanStore(_ inner: MemoryDenialPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialPlanStore {
        return CachedDenialPlanStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial plans. Empty fields match all.
    final class DenialPlanQuery {
        var country: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialPlan) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DenialPlan]) -> [DenialPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialPlans(_ store: any DenialPlanStore, query: DenialPlanQuery) -> [DenialPlan] {
        return query.apply(store.list())
    }
}
