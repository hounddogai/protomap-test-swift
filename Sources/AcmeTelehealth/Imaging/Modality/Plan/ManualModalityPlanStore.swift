import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps manual modality plans by code.
    protocol ManualModalityPlanStore {
        func find(_ code: String) -> ManualModalityPlan?
        func save(_ item: ManualModalityPlan)
        func remove(_ code: String) -> Bool
        func list() -> [ManualModalityPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualModalityPlanStore: ManualModalityPlanStore {
        var items: [String: ManualModalityPlan]
        var order: [String]

        init(items: [String: ManualModalityPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualModalityPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualModalityPlan) {
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

        func list() -> [ManualModalityPlan] {
            var out: [ManualModalityPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualModalityPlanStore() -> any ManualModalityPlanStore {
        return MemoryManualModalityPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualModalityPlanStore: ManualModalityPlanStore {
        var inner: MemoryManualModalityPlanStore
        var cache: TTLCache<ManualModalityPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualModalityPlanStore, cache: TTLCache<ManualModalityPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualModalityPlan? {
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

        func save(_ item: ManualModalityPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualModalityPlan] {
            return inner.list()
        }
    }

    static func newCachedManualModalityPlanStore(_ inner: MemoryManualModalityPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualModalityPlanStore {
        return CachedManualModalityPlanStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual modality plans. Empty fields match all.
    final class ManualModalityPlanQuery {
        var locale: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualModalityPlan) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualModalityPlan]) -> [ManualModalityPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualModalityPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualModalityPlans(_ store: any ManualModalityPlanStore, query: ManualModalityPlanQuery) -> [ManualModalityPlan] {
        return query.apply(store.list())
    }
}
