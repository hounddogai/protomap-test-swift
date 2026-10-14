import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps seasonal handoff budgets by code.
    protocol SeasonalHandoffBudgetStore {
        func find(_ code: String) -> SeasonalHandoffBudget?
        func save(_ item: SeasonalHandoffBudget)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalHandoffBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalHandoffBudgetStore: SeasonalHandoffBudgetStore {
        var items: [String: SeasonalHandoffBudget]
        var order: [String]

        init(items: [String: SeasonalHandoffBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalHandoffBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalHandoffBudget) {
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

        func list() -> [SeasonalHandoffBudget] {
            var out: [SeasonalHandoffBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalHandoffBudgetStore() -> any SeasonalHandoffBudgetStore {
        return MemorySeasonalHandoffBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalHandoffBudgetStore: SeasonalHandoffBudgetStore {
        var inner: MemorySeasonalHandoffBudgetStore
        var cache: TTLCache<SeasonalHandoffBudget>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalHandoffBudgetStore, cache: TTLCache<SeasonalHandoffBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalHandoffBudget? {
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

        func save(_ item: SeasonalHandoffBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalHandoffBudget] {
            return inner.list()
        }
    }

    static func newCachedSeasonalHandoffBudgetStore(_ inner: MemorySeasonalHandoffBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalHandoffBudgetStore {
        return CachedSeasonalHandoffBudgetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal handoff budgets. Empty fields match all.
    final class SeasonalHandoffBudgetQuery {
        var name: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalHandoffBudget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [SeasonalHandoffBudget]) -> [SeasonalHandoffBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalHandoffBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalHandoffBudgets(_ store: any SeasonalHandoffBudgetStore, query: SeasonalHandoffBudgetQuery) -> [SeasonalHandoffBudget] {
        return query.apply(store.list())
    }
}
