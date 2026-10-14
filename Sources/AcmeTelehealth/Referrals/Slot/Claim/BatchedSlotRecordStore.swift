import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps batched slot records by code.
    protocol BatchedSlotRecordStore {
        func find(_ code: String) -> BatchedSlotRecord?
        func save(_ item: BatchedSlotRecord)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedSlotRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedSlotRecordStore: BatchedSlotRecordStore {
        var items: [String: BatchedSlotRecord]
        var order: [String]

        init(items: [String: BatchedSlotRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedSlotRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedSlotRecord) {
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

        func list() -> [BatchedSlotRecord] {
            var out: [BatchedSlotRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedSlotRecordStore() -> any BatchedSlotRecordStore {
        return MemoryBatchedSlotRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedSlotRecordStore: BatchedSlotRecordStore {
        var inner: MemoryBatchedSlotRecordStore
        var cache: TTLCache<BatchedSlotRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedSlotRecordStore, cache: TTLCache<BatchedSlotRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedSlotRecord? {
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

        func save(_ item: BatchedSlotRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedSlotRecord] {
            return inner.list()
        }
    }

    static func newCachedBatchedSlotRecordStore(_ inner: MemoryBatchedSlotRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedSlotRecordStore {
        return CachedBatchedSlotRecordStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched slot records. Empty fields match all.
    final class BatchedSlotRecordQuery {
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

        func matches(_ item: BatchedSlotRecord) -> Bool {
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

        func apply(_ items: [BatchedSlotRecord]) -> [BatchedSlotRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedSlotRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedSlotRecords(_ store: any BatchedSlotRecordStore, query: BatchedSlotRecordQuery) -> [BatchedSlotRecord] {
        return query.apply(store.list())
    }
}
