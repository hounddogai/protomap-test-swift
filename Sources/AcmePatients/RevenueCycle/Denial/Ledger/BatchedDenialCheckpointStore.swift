import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps batched denial checkpoints by code.
    protocol BatchedDenialCheckpointStore {
        func find(_ code: String) -> BatchedDenialCheckpoint?
        func save(_ item: BatchedDenialCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedDenialCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedDenialCheckpointStore: BatchedDenialCheckpointStore {
        var items: [String: BatchedDenialCheckpoint]
        var order: [String]

        init(items: [String: BatchedDenialCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedDenialCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedDenialCheckpoint) {
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

        func list() -> [BatchedDenialCheckpoint] {
            var out: [BatchedDenialCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedDenialCheckpointStore() -> any BatchedDenialCheckpointStore {
        return MemoryBatchedDenialCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedDenialCheckpointStore: BatchedDenialCheckpointStore {
        var inner: MemoryBatchedDenialCheckpointStore
        var cache: TTLCache<BatchedDenialCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedDenialCheckpointStore, cache: TTLCache<BatchedDenialCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedDenialCheckpoint? {
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

        func save(_ item: BatchedDenialCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedDenialCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedBatchedDenialCheckpointStore(_ inner: MemoryBatchedDenialCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedDenialCheckpointStore {
        return CachedBatchedDenialCheckpointStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched denial checkpoints. Empty fields match all.
    final class BatchedDenialCheckpointQuery {
        var locale: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedDenialCheckpoint) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedDenialCheckpoint]) -> [BatchedDenialCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedDenialCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedDenialCheckpoints(_ store: any BatchedDenialCheckpointStore, query: BatchedDenialCheckpointQuery) -> [BatchedDenialCheckpoint] {
        return query.apply(store.list())
    }
}
