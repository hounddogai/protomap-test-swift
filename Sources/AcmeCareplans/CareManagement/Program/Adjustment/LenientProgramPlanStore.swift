import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps lenient program plans by code.
    protocol LenientProgramPlanStore {
        func find(_ code: String) -> LenientProgramPlan?
        func save(_ item: LenientProgramPlan)
        func remove(_ code: String) -> Bool
        func list() -> [LenientProgramPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientProgramPlanStore: LenientProgramPlanStore {
        var items: [String: LenientProgramPlan]
        var order: [String]

        init(items: [String: LenientProgramPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientProgramPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientProgramPlan) {
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

        func list() -> [LenientProgramPlan] {
            var out: [LenientProgramPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientProgramPlanStore() -> any LenientProgramPlanStore {
        return MemoryLenientProgramPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientProgramPlanStore: LenientProgramPlanStore {
        var inner: MemoryLenientProgramPlanStore
        var cache: TTLCache<LenientProgramPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientProgramPlanStore, cache: TTLCache<LenientProgramPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientProgramPlan? {
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

        func save(_ item: LenientProgramPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientProgramPlan] {
            return inner.list()
        }
    }

    static func newCachedLenientProgramPlanStore(_ inner: MemoryLenientProgramPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientProgramPlanStore {
        return CachedLenientProgramPlanStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient program plans. Empty fields match all.
    final class LenientProgramPlanQuery {
        var name: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientProgramPlan) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientProgramPlan]) -> [LenientProgramPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientProgramPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientProgramPlans(_ store: any LenientProgramPlanStore, query: LenientProgramPlanQuery) -> [LenientProgramPlan] {
        return query.apply(store.list())
    }
}
