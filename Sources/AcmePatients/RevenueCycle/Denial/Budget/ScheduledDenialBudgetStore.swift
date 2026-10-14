import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps scheduled denial budgets by code.
    protocol ScheduledDenialBudgetStore {
        func find(_ code: String) -> ScheduledDenialBudget?
        func save(_ item: ScheduledDenialBudget)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledDenialBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledDenialBudgetStore: ScheduledDenialBudgetStore {
        var items: [String: ScheduledDenialBudget]
        var order: [String]

        init(items: [String: ScheduledDenialBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledDenialBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledDenialBudget) {
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

        func list() -> [ScheduledDenialBudget] {
            var out: [ScheduledDenialBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledDenialBudgetStore() -> any ScheduledDenialBudgetStore {
        return MemoryScheduledDenialBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledDenialBudgetStore: ScheduledDenialBudgetStore {
        var inner: MemoryScheduledDenialBudgetStore
        var cache: TTLCache<ScheduledDenialBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledDenialBudgetStore, cache: TTLCache<ScheduledDenialBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledDenialBudget? {
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

        func save(_ item: ScheduledDenialBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledDenialBudget] {
            return inner.list()
        }
    }

    static func newCachedScheduledDenialBudgetStore(_ inner: MemoryScheduledDenialBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledDenialBudgetStore {
        return CachedScheduledDenialBudgetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled denial budgets. Empty fields match all.
    final class ScheduledDenialBudgetQuery {
        var region: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledDenialBudget) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledDenialBudget]) -> [ScheduledDenialBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledDenialBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledDenialBudgets(_ store: any ScheduledDenialBudgetStore, query: ScheduledDenialBudgetQuery) -> [ScheduledDenialBudget] {
        return query.apply(store.list())
    }
}
