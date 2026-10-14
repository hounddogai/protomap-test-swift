import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall batches by code.
    protocol RecallBatchStore {
        func find(_ code: String) -> RecallBatch?
        func save(_ item: RecallBatch)
        func remove(_ code: String) -> Bool
        func list() -> [RecallBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallBatchStore: RecallBatchStore {
        var items: [String: RecallBatch]
        var order: [String]

        init(items: [String: RecallBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallBatch) {
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

        func list() -> [RecallBatch] {
            var out: [RecallBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallBatchStore() -> any RecallBatchStore {
        return MemoryRecallBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallBatchStore: RecallBatchStore {
        var inner: MemoryRecallBatchStore
        var cache: TTLCache<RecallBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallBatchStore, cache: TTLCache<RecallBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallBatch? {
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

        func save(_ item: RecallBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallBatch] {
            return inner.list()
        }
    }

    static func newCachedRecallBatchStore(_ inner: MemoryRecallBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallBatchStore {
        return CachedRecallBatchStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall batches. Empty fields match all.
    final class RecallBatchQuery {
        var label: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallBatch) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [RecallBatch]) -> [RecallBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallBatches(_ store: any RecallBatchStore, query: RecallBatchQuery) -> [RecallBatch] {
        return query.apply(store.list())
    }
}
