import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps pending handoff plans by code.
    protocol PendingHandoffPlanStore {
        func find(_ code: String) -> PendingHandoffPlan?
        func save(_ item: PendingHandoffPlan)
        func remove(_ code: String) -> Bool
        func list() -> [PendingHandoffPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingHandoffPlanStore: PendingHandoffPlanStore {
        var items: [String: PendingHandoffPlan]
        var order: [String]

        init(items: [String: PendingHandoffPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingHandoffPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingHandoffPlan) {
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

        func list() -> [PendingHandoffPlan] {
            var out: [PendingHandoffPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingHandoffPlanStore() -> any PendingHandoffPlanStore {
        return MemoryPendingHandoffPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingHandoffPlanStore: PendingHandoffPlanStore {
        var inner: MemoryPendingHandoffPlanStore
        var cache: TTLCache<PendingHandoffPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingHandoffPlanStore, cache: TTLCache<PendingHandoffPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingHandoffPlan? {
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

        func save(_ item: PendingHandoffPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingHandoffPlan] {
            return inner.list()
        }
    }

    static func newCachedPendingHandoffPlanStore(_ inner: MemoryPendingHandoffPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingHandoffPlanStore {
        return CachedPendingHandoffPlanStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending handoff plans. Empty fields match all.
    final class PendingHandoffPlanQuery {
        var label: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minAmount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingHandoffPlan) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingHandoffPlan]) -> [PendingHandoffPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingHandoffPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingHandoffPlans(_ store: any PendingHandoffPlanStore, query: PendingHandoffPlanQuery) -> [PendingHandoffPlan] {
        return query.apply(store.list())
    }
}
