import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement estimates by code.
    protocol StatementEstimateStore {
        func find(_ code: String) -> StatementEstimate?
        func save(_ item: StatementEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [StatementEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementEstimateStore: StatementEstimateStore {
        var items: [String: StatementEstimate]
        var order: [String]

        init(items: [String: StatementEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementEstimate) {
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

        func list() -> [StatementEstimate] {
            var out: [StatementEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementEstimateStore() -> any StatementEstimateStore {
        return MemoryStatementEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementEstimateStore: StatementEstimateStore {
        var inner: MemoryStatementEstimateStore
        var cache: TTLCache<StatementEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementEstimateStore, cache: TTLCache<StatementEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementEstimate? {
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

        func save(_ item: StatementEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementEstimate] {
            return inner.list()
        }
    }

    static func newCachedStatementEstimateStore(_ inner: MemoryStatementEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementEstimateStore {
        return CachedStatementEstimateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement estimates. Empty fields match all.
    final class StatementEstimateQuery {
        var facility: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementEstimate) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [StatementEstimate]) -> [StatementEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementEstimates(_ store: any StatementEstimateStore, query: StatementEstimateQuery) -> [StatementEstimate] {
        return query.apply(store.list())
    }
}
