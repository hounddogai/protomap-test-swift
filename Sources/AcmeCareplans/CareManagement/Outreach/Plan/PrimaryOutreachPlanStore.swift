import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps primary outreach plans by code.
    protocol PrimaryOutreachPlanStore {
        func find(_ code: String) -> PrimaryOutreachPlan?
        func save(_ item: PrimaryOutreachPlan)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryOutreachPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryOutreachPlanStore: PrimaryOutreachPlanStore {
        var items: [String: PrimaryOutreachPlan]
        var order: [String]

        init(items: [String: PrimaryOutreachPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryOutreachPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryOutreachPlan) {
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

        func list() -> [PrimaryOutreachPlan] {
            var out: [PrimaryOutreachPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryOutreachPlanStore() -> any PrimaryOutreachPlanStore {
        return MemoryPrimaryOutreachPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryOutreachPlanStore: PrimaryOutreachPlanStore {
        var inner: MemoryPrimaryOutreachPlanStore
        var cache: TTLCache<PrimaryOutreachPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryOutreachPlanStore, cache: TTLCache<PrimaryOutreachPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryOutreachPlan? {
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

        func save(_ item: PrimaryOutreachPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryOutreachPlan] {
            return inner.list()
        }
    }

    static func newCachedPrimaryOutreachPlanStore(_ inner: MemoryPrimaryOutreachPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryOutreachPlanStore {
        return CachedPrimaryOutreachPlanStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary outreach plans. Empty fields match all.
    final class PrimaryOutreachPlanQuery {
        var channel: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryOutreachPlan) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [PrimaryOutreachPlan]) -> [PrimaryOutreachPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryOutreachPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryOutreachPlans(_ store: any PrimaryOutreachPlanStore, query: PrimaryOutreachPlanQuery) -> [PrimaryOutreachPlan] {
        return query.apply(store.list())
    }
}
