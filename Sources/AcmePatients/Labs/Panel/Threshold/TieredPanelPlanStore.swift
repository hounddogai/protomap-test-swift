import AcmePlatform
import Foundation

extension Labs {
    /// Keeps tiered panel plans by code.
    protocol TieredPanelPlanStore {
        func find(_ code: String) -> TieredPanelPlan?
        func save(_ item: TieredPanelPlan)
        func remove(_ code: String) -> Bool
        func list() -> [TieredPanelPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredPanelPlanStore: TieredPanelPlanStore {
        var items: [String: TieredPanelPlan]
        var order: [String]

        init(items: [String: TieredPanelPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredPanelPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredPanelPlan) {
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

        func list() -> [TieredPanelPlan] {
            var out: [TieredPanelPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredPanelPlanStore() -> any TieredPanelPlanStore {
        return MemoryTieredPanelPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredPanelPlanStore: TieredPanelPlanStore {
        var inner: MemoryTieredPanelPlanStore
        var cache: TTLCache<TieredPanelPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredPanelPlanStore, cache: TTLCache<TieredPanelPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredPanelPlan? {
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

        func save(_ item: TieredPanelPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredPanelPlan] {
            return inner.list()
        }
    }

    static func newCachedTieredPanelPlanStore(_ inner: MemoryTieredPanelPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredPanelPlanStore {
        return CachedTieredPanelPlanStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered panel plans. Empty fields match all.
    final class TieredPanelPlanQuery {
        var title: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredPanelPlan) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredPanelPlan]) -> [TieredPanelPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredPanelPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredPanelPlans(_ store: any TieredPanelPlanStore, query: TieredPanelPlanQuery) -> [TieredPanelPlan] {
        return query.apply(store.list())
    }
}
