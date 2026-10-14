import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps tiered follow up batches by code.
    protocol TieredFollowUpBatchStore {
        func find(_ code: String) -> TieredFollowUpBatch?
        func save(_ item: TieredFollowUpBatch)
        func remove(_ code: String) -> Bool
        func list() -> [TieredFollowUpBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredFollowUpBatchStore: TieredFollowUpBatchStore {
        var items: [String: TieredFollowUpBatch]
        var order: [String]

        init(items: [String: TieredFollowUpBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredFollowUpBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredFollowUpBatch) {
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

        func list() -> [TieredFollowUpBatch] {
            var out: [TieredFollowUpBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredFollowUpBatchStore() -> any TieredFollowUpBatchStore {
        return MemoryTieredFollowUpBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredFollowUpBatchStore: TieredFollowUpBatchStore {
        var inner: MemoryTieredFollowUpBatchStore
        var cache: TTLCache<TieredFollowUpBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredFollowUpBatchStore, cache: TTLCache<TieredFollowUpBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredFollowUpBatch? {
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

        func save(_ item: TieredFollowUpBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredFollowUpBatch] {
            return inner.list()
        }
    }

    static func newCachedTieredFollowUpBatchStore(_ inner: MemoryTieredFollowUpBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredFollowUpBatchStore {
        return CachedTieredFollowUpBatchStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered follow up batches. Empty fields match all.
    final class TieredFollowUpBatchQuery {
        var title: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredFollowUpBatch) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [TieredFollowUpBatch]) -> [TieredFollowUpBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredFollowUpBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredFollowUpBatches(_ store: any TieredFollowUpBatchStore, query: TieredFollowUpBatchQuery) -> [TieredFollowUpBatch] {
        return query.apply(store.list())
    }
}
