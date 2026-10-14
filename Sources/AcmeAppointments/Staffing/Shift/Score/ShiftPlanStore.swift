import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift plans by code.
    protocol ShiftPlanStore {
        func find(_ code: String) -> ShiftPlan?
        func save(_ item: ShiftPlan)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftPlanStore: ShiftPlanStore {
        var items: [String: ShiftPlan]
        var order: [String]

        init(items: [String: ShiftPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftPlan) {
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

        func list() -> [ShiftPlan] {
            var out: [ShiftPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftPlanStore() -> any ShiftPlanStore {
        return MemoryShiftPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftPlanStore: ShiftPlanStore {
        var inner: MemoryShiftPlanStore
        var cache: TTLCache<ShiftPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftPlanStore, cache: TTLCache<ShiftPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftPlan? {
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

        func save(_ item: ShiftPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftPlan] {
            return inner.list()
        }
    }

    static func newCachedShiftPlanStore(_ inner: MemoryShiftPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftPlanStore {
        return CachedShiftPlanStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift plans. Empty fields match all.
    final class ShiftPlanQuery {
        var locale: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minLimit: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftPlan) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ShiftPlan]) -> [ShiftPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftPlans(_ store: any ShiftPlanStore, query: ShiftPlanQuery) -> [ShiftPlan] {
        return query.apply(store.list())
    }
}
