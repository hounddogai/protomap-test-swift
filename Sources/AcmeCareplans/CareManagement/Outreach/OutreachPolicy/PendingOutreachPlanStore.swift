import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps pending outreach plans by code.
    protocol PendingOutreachPlanStore {
        func find(_ code: String) -> PendingOutreachPlan?
        func save(_ item: PendingOutreachPlan)
        func remove(_ code: String) -> Bool
        func list() -> [PendingOutreachPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingOutreachPlanStore: PendingOutreachPlanStore {
        var items: [String: PendingOutreachPlan]
        var order: [String]

        init(items: [String: PendingOutreachPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingOutreachPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingOutreachPlan) {
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

        func list() -> [PendingOutreachPlan] {
            var out: [PendingOutreachPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingOutreachPlanStore() -> any PendingOutreachPlanStore {
        return MemoryPendingOutreachPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingOutreachPlanStore: PendingOutreachPlanStore {
        var inner: MemoryPendingOutreachPlanStore
        var cache: TTLCache<PendingOutreachPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingOutreachPlanStore, cache: TTLCache<PendingOutreachPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingOutreachPlan? {
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

        func save(_ item: PendingOutreachPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingOutreachPlan] {
            return inner.list()
        }
    }

    static func newCachedPendingOutreachPlanStore(_ inner: MemoryPendingOutreachPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingOutreachPlanStore {
        return CachedPendingOutreachPlanStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending outreach plans. Empty fields match all.
    final class PendingOutreachPlanQuery {
        var title: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRatio: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingOutreachPlan) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingOutreachPlan]) -> [PendingOutreachPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingOutreachPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingOutreachPlans(_ store: any PendingOutreachPlanStore, query: PendingOutreachPlanQuery) -> [PendingOutreachPlan] {
        return query.apply(store.list())
    }
}
