import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps adaptive cleaning budgets by code.
    protocol AdaptiveCleaningBudgetStore {
        func find(_ code: String) -> AdaptiveCleaningBudget?
        func save(_ item: AdaptiveCleaningBudget)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveCleaningBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveCleaningBudgetStore: AdaptiveCleaningBudgetStore {
        var items: [String: AdaptiveCleaningBudget]
        var order: [String]

        init(items: [String: AdaptiveCleaningBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveCleaningBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveCleaningBudget) {
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

        func list() -> [AdaptiveCleaningBudget] {
            var out: [AdaptiveCleaningBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveCleaningBudgetStore() -> any AdaptiveCleaningBudgetStore {
        return MemoryAdaptiveCleaningBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveCleaningBudgetStore: AdaptiveCleaningBudgetStore {
        var inner: MemoryAdaptiveCleaningBudgetStore
        var cache: TTLCache<AdaptiveCleaningBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveCleaningBudgetStore, cache: TTLCache<AdaptiveCleaningBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveCleaningBudget? {
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

        func save(_ item: AdaptiveCleaningBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveCleaningBudget] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveCleaningBudgetStore(_ inner: MemoryAdaptiveCleaningBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveCleaningBudgetStore {
        return CachedAdaptiveCleaningBudgetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive cleaning budgets. Empty fields match all.
    final class AdaptiveCleaningBudgetQuery {
        var label: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveCleaningBudget) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveCleaningBudget]) -> [AdaptiveCleaningBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveCleaningBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveCleaningBudgets(_ store: any AdaptiveCleaningBudgetStore, query: AdaptiveCleaningBudgetQuery) -> [AdaptiveCleaningBudget] {
        return query.apply(store.list())
    }
}
