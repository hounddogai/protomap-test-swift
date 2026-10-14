import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps batched goal baselines by code.
    protocol BatchedGoalBaselineStore {
        func find(_ code: String) -> BatchedGoalBaseline?
        func save(_ item: BatchedGoalBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedGoalBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedGoalBaselineStore: BatchedGoalBaselineStore {
        var items: [String: BatchedGoalBaseline]
        var order: [String]

        init(items: [String: BatchedGoalBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedGoalBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedGoalBaseline) {
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

        func list() -> [BatchedGoalBaseline] {
            var out: [BatchedGoalBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedGoalBaselineStore() -> any BatchedGoalBaselineStore {
        return MemoryBatchedGoalBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedGoalBaselineStore: BatchedGoalBaselineStore {
        var inner: MemoryBatchedGoalBaselineStore
        var cache: TTLCache<BatchedGoalBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedGoalBaselineStore, cache: TTLCache<BatchedGoalBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedGoalBaseline? {
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

        func save(_ item: BatchedGoalBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedGoalBaseline] {
            return inner.list()
        }
    }

    static func newCachedBatchedGoalBaselineStore(_ inner: MemoryBatchedGoalBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedGoalBaselineStore {
        return CachedBatchedGoalBaselineStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched goal baselines. Empty fields match all.
    final class BatchedGoalBaselineQuery {
        var title: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRefills: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedGoalBaseline) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedGoalBaseline]) -> [BatchedGoalBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedGoalBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedGoalBaselines(_ store: any BatchedGoalBaselineStore, query: BatchedGoalBaselineQuery) -> [BatchedGoalBaseline] {
        return query.apply(store.list())
    }
}
