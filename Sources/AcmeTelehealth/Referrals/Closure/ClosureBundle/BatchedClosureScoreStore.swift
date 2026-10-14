import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps batched closure scores by code.
    protocol BatchedClosureScoreStore {
        func find(_ code: String) -> BatchedClosureScore?
        func save(_ item: BatchedClosureScore)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedClosureScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedClosureScoreStore: BatchedClosureScoreStore {
        var items: [String: BatchedClosureScore]
        var order: [String]

        init(items: [String: BatchedClosureScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedClosureScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedClosureScore) {
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

        func list() -> [BatchedClosureScore] {
            var out: [BatchedClosureScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedClosureScoreStore() -> any BatchedClosureScoreStore {
        return MemoryBatchedClosureScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedClosureScoreStore: BatchedClosureScoreStore {
        var inner: MemoryBatchedClosureScoreStore
        var cache: TTLCache<BatchedClosureScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedClosureScoreStore, cache: TTLCache<BatchedClosureScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedClosureScore? {
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

        func save(_ item: BatchedClosureScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedClosureScore] {
            return inner.list()
        }
    }

    static func newCachedBatchedClosureScoreStore(_ inner: MemoryBatchedClosureScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedClosureScoreStore {
        return CachedBatchedClosureScoreStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched closure scores. Empty fields match all.
    final class BatchedClosureScoreQuery {
        var ward: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minRefills: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedClosureScore) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [BatchedClosureScore]) -> [BatchedClosureScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedClosureScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedClosureScores(_ store: any BatchedClosureScoreStore, query: BatchedClosureScoreQuery) -> [BatchedClosureScore] {
        return query.apply(store.list())
    }
}
