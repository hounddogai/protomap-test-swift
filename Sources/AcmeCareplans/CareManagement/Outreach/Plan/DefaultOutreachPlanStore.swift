import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps default outreach plans by code.
    protocol DefaultOutreachPlanStore {
        func find(_ code: String) -> DefaultOutreachPlan?
        func save(_ item: DefaultOutreachPlan)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultOutreachPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultOutreachPlanStore: DefaultOutreachPlanStore {
        var items: [String: DefaultOutreachPlan]
        var order: [String]

        init(items: [String: DefaultOutreachPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultOutreachPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultOutreachPlan) {
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

        func list() -> [DefaultOutreachPlan] {
            var out: [DefaultOutreachPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultOutreachPlanStore() -> any DefaultOutreachPlanStore {
        return MemoryDefaultOutreachPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultOutreachPlanStore: DefaultOutreachPlanStore {
        var inner: MemoryDefaultOutreachPlanStore
        var cache: TTLCache<DefaultOutreachPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultOutreachPlanStore, cache: TTLCache<DefaultOutreachPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultOutreachPlan? {
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

        func save(_ item: DefaultOutreachPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultOutreachPlan] {
            return inner.list()
        }
    }

    static func newCachedDefaultOutreachPlanStore(_ inner: MemoryDefaultOutreachPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultOutreachPlanStore {
        return CachedDefaultOutreachPlanStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default outreach plans. Empty fields match all.
    final class DefaultOutreachPlanQuery {
        var title: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRevision: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultOutreachPlan) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [DefaultOutreachPlan]) -> [DefaultOutreachPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultOutreachPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultOutreachPlans(_ store: any DefaultOutreachPlanStore, query: DefaultOutreachPlanQuery) -> [DefaultOutreachPlan] {
        return query.apply(store.list())
    }
}
