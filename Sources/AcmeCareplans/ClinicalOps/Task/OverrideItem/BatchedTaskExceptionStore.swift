import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps batched task exceptions by code.
    protocol BatchedTaskExceptionStore {
        func find(_ code: String) -> BatchedTaskException?
        func save(_ item: BatchedTaskException)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedTaskException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedTaskExceptionStore: BatchedTaskExceptionStore {
        var items: [String: BatchedTaskException]
        var order: [String]

        init(items: [String: BatchedTaskException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedTaskException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedTaskException) {
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

        func list() -> [BatchedTaskException] {
            var out: [BatchedTaskException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedTaskExceptionStore() -> any BatchedTaskExceptionStore {
        return MemoryBatchedTaskExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedTaskExceptionStore: BatchedTaskExceptionStore {
        var inner: MemoryBatchedTaskExceptionStore
        var cache: TTLCache<BatchedTaskException>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedTaskExceptionStore, cache: TTLCache<BatchedTaskException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedTaskException? {
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

        func save(_ item: BatchedTaskException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedTaskException] {
            return inner.list()
        }
    }

    static func newCachedBatchedTaskExceptionStore(_ inner: MemoryBatchedTaskExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedTaskExceptionStore {
        return CachedBatchedTaskExceptionStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched task exceptions. Empty fields match all.
    final class BatchedTaskExceptionQuery {
        var segment: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedTaskException) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [BatchedTaskException]) -> [BatchedTaskException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedTaskException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedTaskExceptions(_ store: any BatchedTaskExceptionStore, query: BatchedTaskExceptionQuery) -> [BatchedTaskException] {
        return query.apply(store.list())
    }
}
