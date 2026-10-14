import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps batched cleaning records by code.
    protocol BatchedCleaningRecordStore {
        func find(_ code: String) -> BatchedCleaningRecord?
        func save(_ item: BatchedCleaningRecord)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedCleaningRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedCleaningRecordStore: BatchedCleaningRecordStore {
        var items: [String: BatchedCleaningRecord]
        var order: [String]

        init(items: [String: BatchedCleaningRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedCleaningRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedCleaningRecord) {
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

        func list() -> [BatchedCleaningRecord] {
            var out: [BatchedCleaningRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedCleaningRecordStore() -> any BatchedCleaningRecordStore {
        return MemoryBatchedCleaningRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedCleaningRecordStore: BatchedCleaningRecordStore {
        var inner: MemoryBatchedCleaningRecordStore
        var cache: TTLCache<BatchedCleaningRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedCleaningRecordStore, cache: TTLCache<BatchedCleaningRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedCleaningRecord? {
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

        func save(_ item: BatchedCleaningRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedCleaningRecord] {
            return inner.list()
        }
    }

    static func newCachedBatchedCleaningRecordStore(_ inner: MemoryBatchedCleaningRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedCleaningRecordStore {
        return CachedBatchedCleaningRecordStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched cleaning records. Empty fields match all.
    final class BatchedCleaningRecordQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedCleaningRecord) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedCleaningRecord]) -> [BatchedCleaningRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedCleaningRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedCleaningRecords(_ store: any BatchedCleaningRecordStore, query: BatchedCleaningRecordQuery) -> [BatchedCleaningRecord] {
        return query.apply(store.list())
    }
}
