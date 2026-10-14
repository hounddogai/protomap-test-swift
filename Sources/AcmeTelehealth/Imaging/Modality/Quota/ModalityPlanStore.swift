import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality plans by code.
    protocol ModalityPlanStore {
        func find(_ code: String) -> ModalityPlan?
        func save(_ item: ModalityPlan)
        func remove(_ code: String) -> Bool
        func list() -> [ModalityPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalityPlanStore: ModalityPlanStore {
        var items: [String: ModalityPlan]
        var order: [String]

        init(items: [String: ModalityPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalityPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalityPlan) {
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

        func list() -> [ModalityPlan] {
            var out: [ModalityPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalityPlanStore() -> any ModalityPlanStore {
        return MemoryModalityPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalityPlanStore: ModalityPlanStore {
        var inner: MemoryModalityPlanStore
        var cache: TTLCache<ModalityPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalityPlanStore, cache: TTLCache<ModalityPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalityPlan? {
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

        func save(_ item: ModalityPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalityPlan] {
            return inner.list()
        }
    }

    static func newCachedModalityPlanStore(_ inner: MemoryModalityPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalityPlanStore {
        return CachedModalityPlanStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality plans. Empty fields match all.
    final class ModalityPlanQuery {
        var facility: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minRefills: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ModalityPlan) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [ModalityPlan]) -> [ModalityPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalityPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalityPlans(_ store: any ModalityPlanStore, query: ModalityPlanQuery) -> [ModalityPlan] {
        return query.apply(store.list())
    }
}
