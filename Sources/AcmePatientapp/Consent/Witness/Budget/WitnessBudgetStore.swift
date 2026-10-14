import AcmePlatform
import Foundation

extension Consent {
    /// Keeps witness budgets by code.
    protocol WitnessBudgetStore {
        func find(_ code: String) -> WitnessBudget?
        func save(_ item: WitnessBudget)
        func remove(_ code: String) -> Bool
        func list() -> [WitnessBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWitnessBudgetStore: WitnessBudgetStore {
        var items: [String: WitnessBudget]
        var order: [String]

        init(items: [String: WitnessBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WitnessBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WitnessBudget) {
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

        func list() -> [WitnessBudget] {
            var out: [WitnessBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWitnessBudgetStore() -> any WitnessBudgetStore {
        return MemoryWitnessBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWitnessBudgetStore: WitnessBudgetStore {
        var inner: MemoryWitnessBudgetStore
        var cache: TTLCache<WitnessBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryWitnessBudgetStore, cache: TTLCache<WitnessBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WitnessBudget? {
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

        func save(_ item: WitnessBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WitnessBudget] {
            return inner.list()
        }
    }

    static func newCachedWitnessBudgetStore(_ inner: MemoryWitnessBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WitnessBudgetStore {
        return CachedWitnessBudgetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects witness budgets. Empty fields match all.
    final class WitnessBudgetQuery {
        var region: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minRefills: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WitnessBudget) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WitnessBudget]) -> [WitnessBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WitnessBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWitnessBudgets(_ store: any WitnessBudgetStore, query: WitnessBudgetQuery) -> [WitnessBudget] {
        return query.apply(store.list())
    }
}
