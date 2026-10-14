import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read batches by code.
    protocol ReadBatchStore {
        func find(_ code: String) -> ReadBatch?
        func save(_ item: ReadBatch)
        func remove(_ code: String) -> Bool
        func list() -> [ReadBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadBatchStore: ReadBatchStore {
        var items: [String: ReadBatch]
        var order: [String]

        init(items: [String: ReadBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadBatch) {
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

        func list() -> [ReadBatch] {
            var out: [ReadBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadBatchStore() -> any ReadBatchStore {
        return MemoryReadBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadBatchStore: ReadBatchStore {
        var inner: MemoryReadBatchStore
        var cache: TTLCache<ReadBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadBatchStore, cache: TTLCache<ReadBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadBatch? {
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

        func save(_ item: ReadBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadBatch] {
            return inner.list()
        }
    }

    static func newCachedReadBatchStore(_ inner: MemoryReadBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadBatchStore {
        return CachedReadBatchStore(inner: inner, cache: newTTLCache(64, ttl: ttl, clock: clock), hits: 0, misses: 0)
    }

    /// Selects read batches. Empty fields match all.
    final class ReadBatchQuery {
        var segment: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadBatch) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [ReadBatch]) -> [ReadBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadBatches(_ store: any ReadBatchStore, query: ReadBatchQuery) -> [ReadBatch] {
        return query.apply(store.list())
    }
}
