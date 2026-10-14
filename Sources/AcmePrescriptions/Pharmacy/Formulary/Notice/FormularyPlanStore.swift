import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps formulary plans by code.
    protocol FormularyPlanStore {
        func find(_ code: String) -> FormularyPlan?
        func save(_ item: FormularyPlan)
        func remove(_ code: String) -> Bool
        func list() -> [FormularyPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFormularyPlanStore: FormularyPlanStore {
        var items: [String: FormularyPlan]
        var order: [String]

        init(items: [String: FormularyPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FormularyPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FormularyPlan) {
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

        func list() -> [FormularyPlan] {
            var out: [FormularyPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFormularyPlanStore() -> any FormularyPlanStore {
        return MemoryFormularyPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFormularyPlanStore: FormularyPlanStore {
        var inner: MemoryFormularyPlanStore
        var cache: TTLCache<FormularyPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryFormularyPlanStore, cache: TTLCache<FormularyPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FormularyPlan? {
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

        func save(_ item: FormularyPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FormularyPlan] {
            return inner.list()
        }
    }

    static func newCachedFormularyPlanStore(_ inner: MemoryFormularyPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FormularyPlanStore {
        return CachedFormularyPlanStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects formulary plans. Empty fields match all.
    final class FormularyPlanQuery {
        var channel: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FormularyPlan) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FormularyPlan]) -> [FormularyPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FormularyPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFormularyPlans(_ store: any FormularyPlanStore, query: FormularyPlanQuery) -> [FormularyPlan] {
        return query.apply(store.list())
    }
}
