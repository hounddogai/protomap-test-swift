import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement exceptions by code.
    protocol StatementExceptionStore {
        func find(_ code: String) -> StatementException?
        func save(_ item: StatementException)
        func remove(_ code: String) -> Bool
        func list() -> [StatementException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementExceptionStore: StatementExceptionStore {
        var items: [String: StatementException]
        var order: [String]

        init(items: [String: StatementException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementException) {
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

        func list() -> [StatementException] {
            var out: [StatementException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementExceptionStore() -> any StatementExceptionStore {
        return MemoryStatementExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementExceptionStore: StatementExceptionStore {
        var inner: MemoryStatementExceptionStore
        var cache: TTLCache<StatementException>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementExceptionStore, cache: TTLCache<StatementException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementException? {
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

        func save(_ item: StatementException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementException] {
            return inner.list()
        }
    }

    static func newCachedStatementExceptionStore(_ inner: MemoryStatementExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementExceptionStore {
        return CachedStatementExceptionStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement exceptions. Empty fields match all.
    final class StatementExceptionQuery {
        var label: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementException) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StatementException]) -> [StatementException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementExceptions(_ store: any StatementExceptionStore, query: StatementExceptionQuery) -> [StatementException] {
        return query.apply(store.list())
    }
}
