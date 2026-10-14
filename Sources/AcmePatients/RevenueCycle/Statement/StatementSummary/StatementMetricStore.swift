import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement metrics by code.
    protocol StatementMetricStore {
        func find(_ code: String) -> StatementMetric?
        func save(_ item: StatementMetric)
        func remove(_ code: String) -> Bool
        func list() -> [StatementMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementMetricStore: StatementMetricStore {
        var items: [String: StatementMetric]
        var order: [String]

        init(items: [String: StatementMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementMetric) {
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

        func list() -> [StatementMetric] {
            var out: [StatementMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementMetricStore() -> any StatementMetricStore {
        return MemoryStatementMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementMetricStore: StatementMetricStore {
        var inner: MemoryStatementMetricStore
        var cache: TTLCache<StatementMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementMetricStore, cache: TTLCache<StatementMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementMetric? {
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

        func save(_ item: StatementMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementMetric] {
            return inner.list()
        }
    }

    static func newCachedStatementMetricStore(_ inner: MemoryStatementMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementMetricStore {
        return CachedStatementMetricStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement metrics. Empty fields match all.
    final class StatementMetricQuery {
        var ward: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementMetric) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [StatementMetric]) -> [StatementMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementMetrics(_ store: any StatementMetricStore, query: StatementMetricQuery) -> [StatementMetric] {
        return query.apply(store.list())
    }
}
