import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps adaptive overtime budgets by code.
    protocol AdaptiveOvertimeBudgetStore {
        func find(_ code: String) -> AdaptiveOvertimeBudget?
        func save(_ item: AdaptiveOvertimeBudget)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveOvertimeBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveOvertimeBudgetStore: AdaptiveOvertimeBudgetStore {
        var items: [String: AdaptiveOvertimeBudget]
        var order: [String]

        init(items: [String: AdaptiveOvertimeBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveOvertimeBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveOvertimeBudget) {
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

        func list() -> [AdaptiveOvertimeBudget] {
            var out: [AdaptiveOvertimeBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveOvertimeBudgetStore() -> any AdaptiveOvertimeBudgetStore {
        return MemoryAdaptiveOvertimeBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveOvertimeBudgetStore: AdaptiveOvertimeBudgetStore {
        var inner: MemoryAdaptiveOvertimeBudgetStore
        var cache: TTLCache<AdaptiveOvertimeBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveOvertimeBudgetStore, cache: TTLCache<AdaptiveOvertimeBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveOvertimeBudget? {
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

        func save(_ item: AdaptiveOvertimeBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveOvertimeBudget] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveOvertimeBudgetStore(_ inner: MemoryAdaptiveOvertimeBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveOvertimeBudgetStore {
        return CachedAdaptiveOvertimeBudgetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive overtime budgets. Empty fields match all.
    final class AdaptiveOvertimeBudgetQuery {
        var label: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveOvertimeBudget) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [AdaptiveOvertimeBudget]) -> [AdaptiveOvertimeBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveOvertimeBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveOvertimeBudgets(_ store: any AdaptiveOvertimeBudgetStore, query: AdaptiveOvertimeBudgetQuery) -> [AdaptiveOvertimeBudget] {
        return query.apply(store.list())
    }
}
