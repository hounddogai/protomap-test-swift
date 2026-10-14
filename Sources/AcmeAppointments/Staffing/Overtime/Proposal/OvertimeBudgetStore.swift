import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime budgets by code.
    protocol OvertimeBudgetStore {
        func find(_ code: String) -> OvertimeBudget?
        func save(_ item: OvertimeBudget)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeBudgetStore: OvertimeBudgetStore {
        var items: [String: OvertimeBudget]
        var order: [String]

        init(items: [String: OvertimeBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeBudget) {
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

        func list() -> [OvertimeBudget] {
            var out: [OvertimeBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeBudgetStore() -> any OvertimeBudgetStore {
        return MemoryOvertimeBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeBudgetStore: OvertimeBudgetStore {
        var inner: MemoryOvertimeBudgetStore
        var cache: TTLCache<OvertimeBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeBudgetStore, cache: TTLCache<OvertimeBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeBudget? {
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

        func save(_ item: OvertimeBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeBudget] {
            return inner.list()
        }
    }

    static func newCachedOvertimeBudgetStore(_ inner: MemoryOvertimeBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeBudgetStore {
        return CachedOvertimeBudgetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime budgets. Empty fields match all.
    final class OvertimeBudgetQuery {
        var channel: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeBudget) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OvertimeBudget]) -> [OvertimeBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeBudgets(_ store: any OvertimeBudgetStore, query: OvertimeBudgetQuery) -> [OvertimeBudget] {
        return query.apply(store.list())
    }
}
