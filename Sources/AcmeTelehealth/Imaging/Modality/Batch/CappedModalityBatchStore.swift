import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps capped modality batches by code.
    protocol CappedModalityBatchStore {
        func find(_ code: String) -> CappedModalityBatch?
        func save(_ item: CappedModalityBatch)
        func remove(_ code: String) -> Bool
        func list() -> [CappedModalityBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedModalityBatchStore: CappedModalityBatchStore {
        var items: [String: CappedModalityBatch]
        var order: [String]

        init(items: [String: CappedModalityBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedModalityBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedModalityBatch) {
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

        func list() -> [CappedModalityBatch] {
            var out: [CappedModalityBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedModalityBatchStore() -> any CappedModalityBatchStore {
        return MemoryCappedModalityBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedModalityBatchStore: CappedModalityBatchStore {
        var inner: MemoryCappedModalityBatchStore
        var cache: TTLCache<CappedModalityBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedModalityBatchStore, cache: TTLCache<CappedModalityBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedModalityBatch? {
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

        func save(_ item: CappedModalityBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedModalityBatch] {
            return inner.list()
        }
    }

    static func newCachedCappedModalityBatchStore(_ inner: MemoryCappedModalityBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedModalityBatchStore {
        return CachedCappedModalityBatchStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped modality batches. Empty fields match all.
    final class CappedModalityBatchQuery {
        var channel: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedModalityBatch) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedModalityBatch]) -> [CappedModalityBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedModalityBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedModalityBatches(_ store: any CappedModalityBatchStore, query: CappedModalityBatchQuery) -> [CappedModalityBatch] {
        return query.apply(store.list())
    }
}
