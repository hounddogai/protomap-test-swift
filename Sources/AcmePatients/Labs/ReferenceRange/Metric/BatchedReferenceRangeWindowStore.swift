import AcmePlatform
import Foundation

extension Labs {
    /// Keeps batched reference range windows by code.
    protocol BatchedReferenceRangeWindowStore {
        func find(_ code: String) -> BatchedReferenceRangeWindow?
        func save(_ item: BatchedReferenceRangeWindow)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedReferenceRangeWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedReferenceRangeWindowStore: BatchedReferenceRangeWindowStore {
        var items: [String: BatchedReferenceRangeWindow]
        var order: [String]

        init(items: [String: BatchedReferenceRangeWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedReferenceRangeWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedReferenceRangeWindow) {
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

        func list() -> [BatchedReferenceRangeWindow] {
            var out: [BatchedReferenceRangeWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedReferenceRangeWindowStore() -> any BatchedReferenceRangeWindowStore {
        return MemoryBatchedReferenceRangeWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedReferenceRangeWindowStore: BatchedReferenceRangeWindowStore {
        var inner: MemoryBatchedReferenceRangeWindowStore
        var cache: TTLCache<BatchedReferenceRangeWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedReferenceRangeWindowStore, cache: TTLCache<BatchedReferenceRangeWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedReferenceRangeWindow? {
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

        func save(_ item: BatchedReferenceRangeWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedReferenceRangeWindow] {
            return inner.list()
        }
    }

    static func newCachedBatchedReferenceRangeWindowStore(_ inner: MemoryBatchedReferenceRangeWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedReferenceRangeWindowStore {
        return CachedBatchedReferenceRangeWindowStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched reference range windows. Empty fields match all.
    final class BatchedReferenceRangeWindowQuery {
        var title: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedReferenceRangeWindow) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedReferenceRangeWindow]) -> [BatchedReferenceRangeWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedReferenceRangeWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedReferenceRangeWindows(_ store: any BatchedReferenceRangeWindowStore, query: BatchedReferenceRangeWindowQuery) -> [BatchedReferenceRangeWindow] {
        return query.apply(store.list())
    }
}
