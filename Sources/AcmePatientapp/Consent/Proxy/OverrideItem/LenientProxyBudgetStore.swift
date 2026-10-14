import AcmePlatform
import Foundation

extension Consent {
    /// Keeps lenient proxy budgets by code.
    protocol LenientProxyBudgetStore {
        func find(_ code: String) -> LenientProxyBudget?
        func save(_ item: LenientProxyBudget)
        func remove(_ code: String) -> Bool
        func list() -> [LenientProxyBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientProxyBudgetStore: LenientProxyBudgetStore {
        var items: [String: LenientProxyBudget]
        var order: [String]

        init(items: [String: LenientProxyBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientProxyBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientProxyBudget) {
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

        func list() -> [LenientProxyBudget] {
            var out: [LenientProxyBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientProxyBudgetStore() -> any LenientProxyBudgetStore {
        return MemoryLenientProxyBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientProxyBudgetStore: LenientProxyBudgetStore {
        var inner: MemoryLenientProxyBudgetStore
        var cache: TTLCache<LenientProxyBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientProxyBudgetStore, cache: TTLCache<LenientProxyBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientProxyBudget? {
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

        func save(_ item: LenientProxyBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientProxyBudget] {
            return inner.list()
        }
    }

    static func newCachedLenientProxyBudgetStore(_ inner: MemoryLenientProxyBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientProxyBudgetStore {
        return CachedLenientProxyBudgetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient proxy budgets. Empty fields match all.
    final class LenientProxyBudgetQuery {
        var label: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientProxyBudget) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientProxyBudget]) -> [LenientProxyBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientProxyBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientProxyBudgets(_ store: any LenientProxyBudgetStore, query: LenientProxyBudgetQuery) -> [LenientProxyBudget] {
        return query.apply(store.list())
    }
}
