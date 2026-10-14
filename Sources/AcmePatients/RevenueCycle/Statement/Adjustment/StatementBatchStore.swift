import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement batches by code.
    protocol StatementBatchStore {
        func find(_ code: String) -> StatementBatch?
        func save(_ item: StatementBatch)
        func remove(_ code: String) -> Bool
        func list() -> [StatementBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementBatchStore: StatementBatchStore {
        var items: [String: StatementBatch]
        var order: [String]

        init(items: [String: StatementBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementBatch) {
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

        func list() -> [StatementBatch] {
            var out: [StatementBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementBatchStore() -> any StatementBatchStore {
        return MemoryStatementBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementBatchStore: StatementBatchStore {
        var inner: MemoryStatementBatchStore
        var cache: TTLCache<StatementBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementBatchStore, cache: TTLCache<StatementBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementBatch? {
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

        func save(_ item: StatementBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementBatch] {
            return inner.list()
        }
    }

    static func newCachedStatementBatchStore(_ inner: MemoryStatementBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementBatchStore {
        return CachedStatementBatchStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement batches. Empty fields match all.
    final class StatementBatchQuery {
        var ward: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementBatch) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StatementBatch]) -> [StatementBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementBatches(_ store: any StatementBatchStore, query: StatementBatchQuery) -> [StatementBatch] {
        return query.apply(store.list())
    }
}
