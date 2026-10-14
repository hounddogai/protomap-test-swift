import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered study budgets by code.
    protocol TieredStudyBudgetStore {
        func find(_ code: String) -> TieredStudyBudget?
        func save(_ item: TieredStudyBudget)
        func remove(_ code: String) -> Bool
        func list() -> [TieredStudyBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredStudyBudgetStore: TieredStudyBudgetStore {
        var items: [String: TieredStudyBudget]
        var order: [String]

        init(items: [String: TieredStudyBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredStudyBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredStudyBudget) {
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

        func list() -> [TieredStudyBudget] {
            var out: [TieredStudyBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredStudyBudgetStore() -> any TieredStudyBudgetStore {
        return MemoryTieredStudyBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredStudyBudgetStore: TieredStudyBudgetStore {
        var inner: MemoryTieredStudyBudgetStore
        var cache: TTLCache<TieredStudyBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredStudyBudgetStore, cache: TTLCache<TieredStudyBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredStudyBudget? {
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

        func save(_ item: TieredStudyBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredStudyBudget] {
            return inner.list()
        }
    }

    static func newCachedTieredStudyBudgetStore(_ inner: MemoryTieredStudyBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredStudyBudgetStore {
        return CachedTieredStudyBudgetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered study budgets. Empty fields match all.
    final class TieredStudyBudgetQuery {
        var name: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCopay: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredStudyBudget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredStudyBudget]) -> [TieredStudyBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredStudyBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredStudyBudgets(_ store: any TieredStudyBudgetStore, query: TieredStudyBudgetQuery) -> [TieredStudyBudget] {
        return query.apply(store.list())
    }
}
