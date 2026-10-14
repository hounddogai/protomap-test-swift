import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement rollups by code.
    protocol StatementRollupStore {
        func find(_ code: String) -> StatementRollup?
        func save(_ item: StatementRollup)
        func remove(_ code: String) -> Bool
        func list() -> [StatementRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementRollupStore: StatementRollupStore {
        var items: [String: StatementRollup]
        var order: [String]

        init(items: [String: StatementRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementRollup) {
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

        func list() -> [StatementRollup] {
            var out: [StatementRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementRollupStore() -> any StatementRollupStore {
        return MemoryStatementRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementRollupStore: StatementRollupStore {
        var inner: MemoryStatementRollupStore
        var cache: TTLCache<StatementRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementRollupStore, cache: TTLCache<StatementRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementRollup? {
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

        func save(_ item: StatementRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementRollup] {
            return inner.list()
        }
    }

    static func newCachedStatementRollupStore(_ inner: MemoryStatementRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementRollupStore {
        return CachedStatementRollupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement rollups. Empty fields match all.
    final class StatementRollupQuery {
        var unit: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minRate: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementRollup) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StatementRollup]) -> [StatementRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementRollups(_ store: any StatementRollupStore, query: StatementRollupQuery) -> [StatementRollup] {
        return query.apply(store.list())
    }
}
