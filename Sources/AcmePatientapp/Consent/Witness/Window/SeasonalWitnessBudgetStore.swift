import AcmePlatform
import Foundation

extension Consent {
    /// Keeps seasonal witness budgets by code.
    protocol SeasonalWitnessBudgetStore {
        func find(_ code: String) -> SeasonalWitnessBudget?
        func save(_ item: SeasonalWitnessBudget)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalWitnessBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalWitnessBudgetStore: SeasonalWitnessBudgetStore {
        var items: [String: SeasonalWitnessBudget]
        var order: [String]

        init(items: [String: SeasonalWitnessBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalWitnessBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalWitnessBudget) {
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

        func list() -> [SeasonalWitnessBudget] {
            var out: [SeasonalWitnessBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalWitnessBudgetStore() -> any SeasonalWitnessBudgetStore {
        return MemorySeasonalWitnessBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalWitnessBudgetStore: SeasonalWitnessBudgetStore {
        var inner: MemorySeasonalWitnessBudgetStore
        var cache: TTLCache<SeasonalWitnessBudget>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalWitnessBudgetStore, cache: TTLCache<SeasonalWitnessBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalWitnessBudget? {
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

        func save(_ item: SeasonalWitnessBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalWitnessBudget] {
            return inner.list()
        }
    }

    static func newCachedSeasonalWitnessBudgetStore(_ inner: MemorySeasonalWitnessBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalWitnessBudgetStore {
        return CachedSeasonalWitnessBudgetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal witness budgets. Empty fields match all.
    final class SeasonalWitnessBudgetQuery {
        var source: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minCost: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalWitnessBudget) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalWitnessBudget]) -> [SeasonalWitnessBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalWitnessBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalWitnessBudgets(_ store: any SeasonalWitnessBudgetStore, query: SeasonalWitnessBudgetQuery) -> [SeasonalWitnessBudget] {
        return query.apply(store.list())
    }
}
