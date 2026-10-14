import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement targets by code.
    protocol StatementTargetStore {
        func find(_ code: String) -> StatementTarget?
        func save(_ item: StatementTarget)
        func remove(_ code: String) -> Bool
        func list() -> [StatementTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementTargetStore: StatementTargetStore {
        var items: [String: StatementTarget]
        var order: [String]

        init(items: [String: StatementTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementTarget) {
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

        func list() -> [StatementTarget] {
            var out: [StatementTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementTargetStore() -> any StatementTargetStore {
        return MemoryStatementTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementTargetStore: StatementTargetStore {
        var inner: MemoryStatementTargetStore
        var cache: TTLCache<StatementTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementTargetStore, cache: TTLCache<StatementTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementTarget? {
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

        func save(_ item: StatementTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementTarget] {
            return inner.list()
        }
    }

    static func newCachedStatementTargetStore(_ inner: MemoryStatementTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementTargetStore {
        return CachedStatementTargetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement targets. Empty fields match all.
    final class StatementTargetQuery {
        var name: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementTarget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StatementTarget]) -> [StatementTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementTargets(_ store: any StatementTargetStore, query: StatementTargetQuery) -> [StatementTarget] {
        return query.apply(store.list())
    }
}
