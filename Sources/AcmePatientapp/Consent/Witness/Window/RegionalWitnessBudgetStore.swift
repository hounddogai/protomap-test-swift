import AcmePlatform
import Foundation

extension Consent {
    /// Keeps regional witness budgets by code.
    protocol RegionalWitnessBudgetStore {
        func find(_ code: String) -> RegionalWitnessBudget?
        func save(_ item: RegionalWitnessBudget)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalWitnessBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalWitnessBudgetStore: RegionalWitnessBudgetStore {
        var items: [String: RegionalWitnessBudget]
        var order: [String]

        init(items: [String: RegionalWitnessBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalWitnessBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalWitnessBudget) {
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

        func list() -> [RegionalWitnessBudget] {
            var out: [RegionalWitnessBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalWitnessBudgetStore() -> any RegionalWitnessBudgetStore {
        return MemoryRegionalWitnessBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalWitnessBudgetStore: RegionalWitnessBudgetStore {
        var inner: MemoryRegionalWitnessBudgetStore
        var cache: TTLCache<RegionalWitnessBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalWitnessBudgetStore, cache: TTLCache<RegionalWitnessBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalWitnessBudget? {
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

        func save(_ item: RegionalWitnessBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalWitnessBudget] {
            return inner.list()
        }
    }

    static func newCachedRegionalWitnessBudgetStore(_ inner: MemoryRegionalWitnessBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalWitnessBudgetStore {
        return CachedRegionalWitnessBudgetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional witness budgets. Empty fields match all.
    final class RegionalWitnessBudgetQuery {
        var facility: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minAmount: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalWitnessBudget) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [RegionalWitnessBudget]) -> [RegionalWitnessBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalWitnessBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalWitnessBudgets(_ store: any RegionalWitnessBudgetStore, query: RegionalWitnessBudgetQuery) -> [RegionalWitnessBudget] {
        return query.apply(store.list())
    }
}
