import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel plans by code.
    protocol PanelPlanStore {
        func find(_ code: String) -> PanelPlan?
        func save(_ item: PanelPlan)
        func remove(_ code: String) -> Bool
        func list() -> [PanelPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelPlanStore: PanelPlanStore {
        var items: [String: PanelPlan]
        var order: [String]

        init(items: [String: PanelPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelPlan) {
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

        func list() -> [PanelPlan] {
            var out: [PanelPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelPlanStore() -> any PanelPlanStore {
        return MemoryPanelPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelPlanStore: PanelPlanStore {
        var inner: MemoryPanelPlanStore
        var cache: TTLCache<PanelPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelPlanStore, cache: TTLCache<PanelPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelPlan? {
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

        func save(_ item: PanelPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelPlan] {
            return inner.list()
        }
    }

    static func newCachedPanelPlanStore(_ inner: MemoryPanelPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelPlanStore {
        return CachedPanelPlanStore(inner: inner, cache: newTTLCache(64, ttl: ttl, clock: clock), hits: 0, misses: 0)
    }

    /// Selects panel plans. Empty fields match all.
    final class PanelPlanQuery {
        var title: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRefills: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelPlan) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [PanelPlan]) -> [PanelPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelPlans(_ store: any PanelPlanStore, query: PanelPlanQuery) -> [PanelPlan] {
        return query.apply(store.list())
    }
}
