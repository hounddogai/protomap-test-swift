import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction budgets by code.
    protocol InteractionBudgetStore {
        func find(_ code: String) -> InteractionBudget?
        func save(_ item: InteractionBudget)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionBudgetStore: InteractionBudgetStore {
        var items: [String: InteractionBudget]
        var order: [String]

        init(items: [String: InteractionBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionBudget) {
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

        func list() -> [InteractionBudget] {
            var out: [InteractionBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionBudgetStore() -> any InteractionBudgetStore {
        return MemoryInteractionBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionBudgetStore: InteractionBudgetStore {
        var inner: MemoryInteractionBudgetStore
        var cache: TTLCache<InteractionBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionBudgetStore, cache: TTLCache<InteractionBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionBudget? {
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

        func save(_ item: InteractionBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionBudget] {
            return inner.list()
        }
    }

    static func newCachedInteractionBudgetStore(_ inner: MemoryInteractionBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionBudgetStore {
        return CachedInteractionBudgetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction budgets. Empty fields match all.
    final class InteractionBudgetQuery {
        var locale: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionBudget) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [InteractionBudget]) -> [InteractionBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionBudgets(_ store: any InteractionBudgetStore, query: InteractionBudgetQuery) -> [InteractionBudget] {
        return query.apply(store.list())
    }
}
