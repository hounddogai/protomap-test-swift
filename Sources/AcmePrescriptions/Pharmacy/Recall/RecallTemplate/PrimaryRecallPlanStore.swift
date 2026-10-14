import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps primary recall plans by code.
    protocol PrimaryRecallPlanStore {
        func find(_ code: String) -> PrimaryRecallPlan?
        func save(_ item: PrimaryRecallPlan)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryRecallPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryRecallPlanStore: PrimaryRecallPlanStore {
        var items: [String: PrimaryRecallPlan]
        var order: [String]

        init(items: [String: PrimaryRecallPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryRecallPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryRecallPlan) {
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

        func list() -> [PrimaryRecallPlan] {
            var out: [PrimaryRecallPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryRecallPlanStore() -> any PrimaryRecallPlanStore {
        return MemoryPrimaryRecallPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryRecallPlanStore: PrimaryRecallPlanStore {
        var inner: MemoryPrimaryRecallPlanStore
        var cache: TTLCache<PrimaryRecallPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryRecallPlanStore, cache: TTLCache<PrimaryRecallPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryRecallPlan? {
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

        func save(_ item: PrimaryRecallPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryRecallPlan] {
            return inner.list()
        }
    }

    static func newCachedPrimaryRecallPlanStore(_ inner: MemoryPrimaryRecallPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryRecallPlanStore {
        return CachedPrimaryRecallPlanStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary recall plans. Empty fields match all.
    final class PrimaryRecallPlanQuery {
        var region: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minPriority: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryRecallPlan) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryRecallPlan]) -> [PrimaryRecallPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryRecallPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryRecallPlans(_ store: any PrimaryRecallPlanStore, query: PrimaryRecallPlanQuery) -> [PrimaryRecallPlan] {
        return query.apply(store.list())
    }
}
