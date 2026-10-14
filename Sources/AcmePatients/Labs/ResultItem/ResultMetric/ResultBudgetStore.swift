import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result budgets by code.
    protocol ResultBudgetStore {
        func find(_ code: String) -> ResultBudget?
        func save(_ item: ResultBudget)
        func remove(_ code: String) -> Bool
        func list() -> [ResultBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultBudgetStore: ResultBudgetStore {
        var items: [String: ResultBudget]
        var order: [String]

        init(items: [String: ResultBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultBudget) {
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

        func list() -> [ResultBudget] {
            var out: [ResultBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultBudgetStore() -> any ResultBudgetStore {
        return MemoryResultBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultBudgetStore: ResultBudgetStore {
        var inner: MemoryResultBudgetStore
        var cache: TTLCache<ResultBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultBudgetStore, cache: TTLCache<ResultBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultBudget? {
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

        func save(_ item: ResultBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultBudget] {
            return inner.list()
        }
    }

    static func newCachedResultBudgetStore(_ inner: MemoryResultBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultBudgetStore {
        return CachedResultBudgetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result budgets. Empty fields match all.
    final class ResultBudgetQuery {
        var title: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMargin: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultBudget) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ResultBudget]) -> [ResultBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultBudgets(_ store: any ResultBudgetStore, query: ResultBudgetQuery) -> [ResultBudget] {
        return query.apply(store.list())
    }
}
