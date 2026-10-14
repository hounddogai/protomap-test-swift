import AcmePlatform
import Foundation

extension Labs {
    /// Keeps strict specimen plans by code.
    protocol StrictSpecimenPlanStore {
        func find(_ code: String) -> StrictSpecimenPlan?
        func save(_ item: StrictSpecimenPlan)
        func remove(_ code: String) -> Bool
        func list() -> [StrictSpecimenPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictSpecimenPlanStore: StrictSpecimenPlanStore {
        var items: [String: StrictSpecimenPlan]
        var order: [String]

        init(items: [String: StrictSpecimenPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictSpecimenPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictSpecimenPlan) {
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

        func list() -> [StrictSpecimenPlan] {
            var out: [StrictSpecimenPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictSpecimenPlanStore() -> any StrictSpecimenPlanStore {
        return MemoryStrictSpecimenPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictSpecimenPlanStore: StrictSpecimenPlanStore {
        var inner: MemoryStrictSpecimenPlanStore
        var cache: TTLCache<StrictSpecimenPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictSpecimenPlanStore, cache: TTLCache<StrictSpecimenPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictSpecimenPlan? {
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

        func save(_ item: StrictSpecimenPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictSpecimenPlan] {
            return inner.list()
        }
    }

    static func newCachedStrictSpecimenPlanStore(_ inner: MemoryStrictSpecimenPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictSpecimenPlanStore {
        return CachedStrictSpecimenPlanStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict specimen plans. Empty fields match all.
    final class StrictSpecimenPlanQuery {
        var label: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCopay: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictSpecimenPlan) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictSpecimenPlan]) -> [StrictSpecimenPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictSpecimenPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictSpecimenPlans(_ store: any StrictSpecimenPlanStore, query: StrictSpecimenPlanQuery) -> [StrictSpecimenPlan] {
        return query.apply(store.list())
    }
}
