import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps batched isolation records by code.
    protocol BatchedIsolationRecordStore {
        func find(_ code: String) -> BatchedIsolationRecord?
        func save(_ item: BatchedIsolationRecord)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedIsolationRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedIsolationRecordStore: BatchedIsolationRecordStore {
        var items: [String: BatchedIsolationRecord]
        var order: [String]

        init(items: [String: BatchedIsolationRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedIsolationRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedIsolationRecord) {
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

        func list() -> [BatchedIsolationRecord] {
            var out: [BatchedIsolationRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedIsolationRecordStore() -> any BatchedIsolationRecordStore {
        return MemoryBatchedIsolationRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedIsolationRecordStore: BatchedIsolationRecordStore {
        var inner: MemoryBatchedIsolationRecordStore
        var cache: TTLCache<BatchedIsolationRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedIsolationRecordStore, cache: TTLCache<BatchedIsolationRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedIsolationRecord? {
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

        func save(_ item: BatchedIsolationRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedIsolationRecord] {
            return inner.list()
        }
    }

    static func newCachedBatchedIsolationRecordStore(_ inner: MemoryBatchedIsolationRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedIsolationRecordStore {
        return CachedBatchedIsolationRecordStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched isolation records. Empty fields match all.
    final class BatchedIsolationRecordQuery {
        var label: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedIsolationRecord) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedIsolationRecord]) -> [BatchedIsolationRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedIsolationRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedIsolationRecords(_ store: any BatchedIsolationRecordStore, query: BatchedIsolationRecordQuery) -> [BatchedIsolationRecord] {
        return query.apply(store.list())
    }
}
