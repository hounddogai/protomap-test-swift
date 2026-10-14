import AcmePlatform
import Foundation

extension Labs {
    /// Keeps batched panel scores by code.
    protocol BatchedPanelScoreStore {
        func find(_ code: String) -> BatchedPanelScore?
        func save(_ item: BatchedPanelScore)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedPanelScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedPanelScoreStore: BatchedPanelScoreStore {
        var items: [String: BatchedPanelScore]
        var order: [String]

        init(items: [String: BatchedPanelScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedPanelScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedPanelScore) {
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

        func list() -> [BatchedPanelScore] {
            var out: [BatchedPanelScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedPanelScoreStore() -> any BatchedPanelScoreStore {
        return MemoryBatchedPanelScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedPanelScoreStore: BatchedPanelScoreStore {
        var inner: MemoryBatchedPanelScoreStore
        var cache: TTLCache<BatchedPanelScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedPanelScoreStore, cache: TTLCache<BatchedPanelScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedPanelScore? {
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

        func save(_ item: BatchedPanelScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedPanelScore] {
            return inner.list()
        }
    }

    static func newCachedBatchedPanelScoreStore(_ inner: MemoryBatchedPanelScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedPanelScoreStore {
        return CachedBatchedPanelScoreStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched panel scores. Empty fields match all.
    final class BatchedPanelScoreQuery {
        var title: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minPriority: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedPanelScore) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedPanelScore]) -> [BatchedPanelScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedPanelScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedPanelScores(_ store: any BatchedPanelScoreStore, query: BatchedPanelScoreQuery) -> [BatchedPanelScore] {
        return query.apply(store.list())
    }
}
