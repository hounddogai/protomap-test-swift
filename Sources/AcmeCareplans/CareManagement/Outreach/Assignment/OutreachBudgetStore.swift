import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach budgets by code.
    protocol OutreachBudgetStore {
        func find(_ code: String) -> OutreachBudget?
        func save(_ item: OutreachBudget)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachBudgetStore: OutreachBudgetStore {
        var items: [String: OutreachBudget]
        var order: [String]

        init(items: [String: OutreachBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachBudget) {
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

        func list() -> [OutreachBudget] {
            var out: [OutreachBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachBudgetStore() -> any OutreachBudgetStore {
        return MemoryOutreachBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachBudgetStore: OutreachBudgetStore {
        var inner: MemoryOutreachBudgetStore
        var cache: TTLCache<OutreachBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachBudgetStore, cache: TTLCache<OutreachBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachBudget? {
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

        func save(_ item: OutreachBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachBudget] {
            return inner.list()
        }
    }

    static func newCachedOutreachBudgetStore(_ inner: MemoryOutreachBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachBudgetStore {
        return CachedOutreachBudgetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach budgets. Empty fields match all.
    final class OutreachBudgetQuery {
        var locale: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minAmount: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachBudget) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [OutreachBudget]) -> [OutreachBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachBudgets(_ store: any OutreachBudgetStore, query: OutreachBudgetQuery) -> [OutreachBudget] {
        return query.apply(store.list())
    }
}
