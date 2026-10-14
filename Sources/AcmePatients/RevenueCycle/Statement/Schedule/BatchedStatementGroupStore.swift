import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps batched statement groups by code.
    protocol BatchedStatementGroupStore {
        func find(_ code: String) -> BatchedStatementGroup?
        func save(_ item: BatchedStatementGroup)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedStatementGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedStatementGroupStore: BatchedStatementGroupStore {
        var items: [String: BatchedStatementGroup]
        var order: [String]

        init(items: [String: BatchedStatementGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedStatementGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedStatementGroup) {
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

        func list() -> [BatchedStatementGroup] {
            var out: [BatchedStatementGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedStatementGroupStore() -> any BatchedStatementGroupStore {
        return MemoryBatchedStatementGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedStatementGroupStore: BatchedStatementGroupStore {
        var inner: MemoryBatchedStatementGroupStore
        var cache: TTLCache<BatchedStatementGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedStatementGroupStore, cache: TTLCache<BatchedStatementGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedStatementGroup? {
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

        func save(_ item: BatchedStatementGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedStatementGroup] {
            return inner.list()
        }
    }

    static func newCachedBatchedStatementGroupStore(_ inner: MemoryBatchedStatementGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedStatementGroupStore {
        return CachedBatchedStatementGroupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched statement groups. Empty fields match all.
    final class BatchedStatementGroupQuery {
        var facility: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedStatementGroup) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedStatementGroup]) -> [BatchedStatementGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedStatementGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedStatementGroups(_ store: any BatchedStatementGroupStore, query: BatchedStatementGroupQuery) -> [BatchedStatementGroup] {
        return query.apply(store.list())
    }
}
