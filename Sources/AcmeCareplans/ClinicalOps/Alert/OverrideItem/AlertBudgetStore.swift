import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert budgets by code.
    protocol AlertBudgetStore {
        func find(_ code: String) -> AlertBudget?
        func save(_ item: AlertBudget)
        func remove(_ code: String) -> Bool
        func list() -> [AlertBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertBudgetStore: AlertBudgetStore {
        var items: [String: AlertBudget]
        var order: [String]

        init(items: [String: AlertBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertBudget) {
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

        func list() -> [AlertBudget] {
            var out: [AlertBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertBudgetStore() -> any AlertBudgetStore {
        return MemoryAlertBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertBudgetStore: AlertBudgetStore {
        var inner: MemoryAlertBudgetStore
        var cache: TTLCache<AlertBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertBudgetStore, cache: TTLCache<AlertBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertBudget? {
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

        func save(_ item: AlertBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertBudget] {
            return inner.list()
        }
    }

    static func newCachedAlertBudgetStore(_ inner: MemoryAlertBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertBudgetStore {
        return CachedAlertBudgetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert budgets. Empty fields match all.
    final class AlertBudgetQuery {
        var segment: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertBudget) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AlertBudget]) -> [AlertBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertBudgets(_ store: any AlertBudgetStore, query: AlertBudgetQuery) -> [AlertBudget] {
        return query.apply(store.list())
    }
}
