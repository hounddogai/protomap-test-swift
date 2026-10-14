import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement cycles by code.
    protocol StatementCycleStore {
        func find(_ code: String) -> StatementCycle?
        func save(_ item: StatementCycle)
        func remove(_ code: String) -> Bool
        func list() -> [StatementCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementCycleStore: StatementCycleStore {
        var items: [String: StatementCycle]
        var order: [String]

        init(items: [String: StatementCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementCycle) {
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

        func list() -> [StatementCycle] {
            var out: [StatementCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementCycleStore() -> any StatementCycleStore {
        return MemoryStatementCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementCycleStore: StatementCycleStore {
        var inner: MemoryStatementCycleStore
        var cache: TTLCache<StatementCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementCycleStore, cache: TTLCache<StatementCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementCycle? {
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

        func save(_ item: StatementCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementCycle] {
            return inner.list()
        }
    }

    static func newCachedStatementCycleStore(_ inner: MemoryStatementCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementCycleStore {
        return CachedStatementCycleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement cycles. Empty fields match all.
    final class StatementCycleQuery {
        var name: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementCycle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StatementCycle]) -> [StatementCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementCycles(_ store: any StatementCycleStore, query: StatementCycleQuery) -> [StatementCycle] {
        return query.apply(store.list())
    }
}
