import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered study batches by code.
    protocol TieredStudyBatchStore {
        func find(_ code: String) -> TieredStudyBatch?
        func save(_ item: TieredStudyBatch)
        func remove(_ code: String) -> Bool
        func list() -> [TieredStudyBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredStudyBatchStore: TieredStudyBatchStore {
        var items: [String: TieredStudyBatch]
        var order: [String]

        init(items: [String: TieredStudyBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredStudyBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredStudyBatch) {
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

        func list() -> [TieredStudyBatch] {
            var out: [TieredStudyBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredStudyBatchStore() -> any TieredStudyBatchStore {
        return MemoryTieredStudyBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredStudyBatchStore: TieredStudyBatchStore {
        var inner: MemoryTieredStudyBatchStore
        var cache: TTLCache<TieredStudyBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredStudyBatchStore, cache: TTLCache<TieredStudyBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredStudyBatch? {
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

        func save(_ item: TieredStudyBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredStudyBatch] {
            return inner.list()
        }
    }

    static func newCachedTieredStudyBatchStore(_ inner: MemoryTieredStudyBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredStudyBatchStore {
        return CachedTieredStudyBatchStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered study batches. Empty fields match all.
    final class TieredStudyBatchQuery {
        var name: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRetries: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredStudyBatch) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredStudyBatch]) -> [TieredStudyBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredStudyBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredStudyBatches(_ store: any TieredStudyBatchStore, query: TieredStudyBatchQuery) -> [TieredStudyBatch] {
        return query.apply(store.list())
    }
}
