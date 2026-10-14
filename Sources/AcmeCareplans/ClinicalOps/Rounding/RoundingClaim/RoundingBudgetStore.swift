import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding budgets by code.
    protocol RoundingBudgetStore {
        func find(_ code: String) -> RoundingBudget?
        func save(_ item: RoundingBudget)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingBudgetStore: RoundingBudgetStore {
        var items: [String: RoundingBudget]
        var order: [String]

        init(items: [String: RoundingBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingBudget) {
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

        func list() -> [RoundingBudget] {
            var out: [RoundingBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingBudgetStore() -> any RoundingBudgetStore {
        return MemoryRoundingBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingBudgetStore: RoundingBudgetStore {
        var inner: MemoryRoundingBudgetStore
        var cache: TTLCache<RoundingBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingBudgetStore, cache: TTLCache<RoundingBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingBudget? {
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

        func save(_ item: RoundingBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingBudget] {
            return inner.list()
        }
    }

    static func newCachedRoundingBudgetStore(_ inner: MemoryRoundingBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingBudgetStore {
        return CachedRoundingBudgetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding budgets. Empty fields match all.
    final class RoundingBudgetQuery {
        var segment: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingBudget) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingBudget]) -> [RoundingBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingBudgets(_ store: any RoundingBudgetStore, query: RoundingBudgetQuery) -> [RoundingBudget] {
        return query.apply(store.list())
    }
}
