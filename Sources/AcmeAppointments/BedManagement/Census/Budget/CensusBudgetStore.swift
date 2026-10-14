import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps census budgets by code.
    protocol CensusBudgetStore {
        func find(_ code: String) -> CensusBudget?
        func save(_ item: CensusBudget)
        func remove(_ code: String) -> Bool
        func list() -> [CensusBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCensusBudgetStore: CensusBudgetStore {
        var items: [String: CensusBudget]
        var order: [String]

        init(items: [String: CensusBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CensusBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CensusBudget) {
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

        func list() -> [CensusBudget] {
            var out: [CensusBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCensusBudgetStore() -> any CensusBudgetStore {
        return MemoryCensusBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCensusBudgetStore: CensusBudgetStore {
        var inner: MemoryCensusBudgetStore
        var cache: TTLCache<CensusBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryCensusBudgetStore, cache: TTLCache<CensusBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CensusBudget? {
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

        func save(_ item: CensusBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CensusBudget] {
            return inner.list()
        }
    }

    static func newCachedCensusBudgetStore(_ inner: MemoryCensusBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CensusBudgetStore {
        return CachedCensusBudgetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects census budgets. Empty fields match all.
    final class CensusBudgetQuery {
        var unit: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CensusBudget) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CensusBudget]) -> [CensusBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CensusBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCensusBudgets(_ store: any CensusBudgetStore, query: CensusBudgetQuery) -> [CensusBudget] {
        return query.apply(store.list())
    }
}
