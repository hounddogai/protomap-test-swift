import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps pending read budgets by code.
    protocol PendingReadBudgetStore {
        func find(_ code: String) -> PendingReadBudget?
        func save(_ item: PendingReadBudget)
        func remove(_ code: String) -> Bool
        func list() -> [PendingReadBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingReadBudgetStore: PendingReadBudgetStore {
        var items: [String: PendingReadBudget]
        var order: [String]

        init(items: [String: PendingReadBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingReadBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingReadBudget) {
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

        func list() -> [PendingReadBudget] {
            var out: [PendingReadBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingReadBudgetStore() -> any PendingReadBudgetStore {
        return MemoryPendingReadBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingReadBudgetStore: PendingReadBudgetStore {
        var inner: MemoryPendingReadBudgetStore
        var cache: TTLCache<PendingReadBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingReadBudgetStore, cache: TTLCache<PendingReadBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingReadBudget? {
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

        func save(_ item: PendingReadBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingReadBudget] {
            return inner.list()
        }
    }

    static func newCachedPendingReadBudgetStore(_ inner: MemoryPendingReadBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingReadBudgetStore {
        return CachedPendingReadBudgetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending read budgets. Empty fields match all.
    final class PendingReadBudgetQuery {
        var channel: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCopay: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingReadBudget) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [PendingReadBudget]) -> [PendingReadBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingReadBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingReadBudgets(_ store: any PendingReadBudgetStore, query: PendingReadBudgetQuery) -> [PendingReadBudget] {
        return query.apply(store.list())
    }
}
