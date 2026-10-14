import AcmePlatform
import Foundation

extension Labs {
    /// Keeps batched reference range records by code.
    protocol BatchedReferenceRangeRecordStore {
        func find(_ code: String) -> BatchedReferenceRangeRecord?
        func save(_ item: BatchedReferenceRangeRecord)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedReferenceRangeRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedReferenceRangeRecordStore: BatchedReferenceRangeRecordStore {
        var items: [String: BatchedReferenceRangeRecord]
        var order: [String]

        init(items: [String: BatchedReferenceRangeRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedReferenceRangeRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedReferenceRangeRecord) {
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

        func list() -> [BatchedReferenceRangeRecord] {
            var out: [BatchedReferenceRangeRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedReferenceRangeRecordStore() -> any BatchedReferenceRangeRecordStore {
        return MemoryBatchedReferenceRangeRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedReferenceRangeRecordStore: BatchedReferenceRangeRecordStore {
        var inner: MemoryBatchedReferenceRangeRecordStore
        var cache: TTLCache<BatchedReferenceRangeRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedReferenceRangeRecordStore, cache: TTLCache<BatchedReferenceRangeRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedReferenceRangeRecord? {
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

        func save(_ item: BatchedReferenceRangeRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedReferenceRangeRecord] {
            return inner.list()
        }
    }

    static func newCachedBatchedReferenceRangeRecordStore(_ inner: MemoryBatchedReferenceRangeRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedReferenceRangeRecordStore {
        return CachedBatchedReferenceRangeRecordStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched reference range records. Empty fields match all.
    final class BatchedReferenceRangeRecordQuery {
        var title: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMargin: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedReferenceRangeRecord) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedReferenceRangeRecord]) -> [BatchedReferenceRangeRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedReferenceRangeRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedReferenceRangeRecords(_ store: any BatchedReferenceRangeRecordStore, query: BatchedReferenceRangeRecordQuery) -> [BatchedReferenceRangeRecord] {
        return query.apply(store.list())
    }
}
