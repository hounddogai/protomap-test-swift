import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap budgets by code.
    protocol CareGapBudgetStore {
        func find(_ code: String) -> CareGapBudget?
        func save(_ item: CareGapBudget)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapBudgetStore: CareGapBudgetStore {
        var items: [String: CareGapBudget]
        var order: [String]

        init(items: [String: CareGapBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapBudget) {
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

        func list() -> [CareGapBudget] {
            var out: [CareGapBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapBudgetStore() -> any CareGapBudgetStore {
        return MemoryCareGapBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapBudgetStore: CareGapBudgetStore {
        var inner: MemoryCareGapBudgetStore
        var cache: TTLCache<CareGapBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapBudgetStore, cache: TTLCache<CareGapBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapBudget? {
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

        func save(_ item: CareGapBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapBudget] {
            return inner.list()
        }
    }

    static func newCachedCareGapBudgetStore(_ inner: MemoryCareGapBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapBudgetStore {
        return CachedCareGapBudgetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap budgets. Empty fields match all.
    final class CareGapBudgetQuery {
        var category: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapBudget) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareGapBudget]) -> [CareGapBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapBudgets(_ store: any CareGapBudgetStore, query: CareGapBudgetQuery) -> [CareGapBudget] {
        return query.apply(store.list())
    }
}
