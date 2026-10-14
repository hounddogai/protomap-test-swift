import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered read batches by code.
    protocol TieredReadBatchStore {
        func find(_ code: String) -> TieredReadBatch?
        func save(_ item: TieredReadBatch)
        func remove(_ code: String) -> Bool
        func list() -> [TieredReadBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredReadBatchStore: TieredReadBatchStore {
        var items: [String: TieredReadBatch]
        var order: [String]

        init(items: [String: TieredReadBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredReadBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredReadBatch) {
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

        func list() -> [TieredReadBatch] {
            var out: [TieredReadBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredReadBatchStore() -> any TieredReadBatchStore {
        return MemoryTieredReadBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredReadBatchStore: TieredReadBatchStore {
        var inner: MemoryTieredReadBatchStore
        var cache: TTLCache<TieredReadBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredReadBatchStore, cache: TTLCache<TieredReadBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredReadBatch? {
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

        func save(_ item: TieredReadBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredReadBatch] {
            return inner.list()
        }
    }

    static func newCachedTieredReadBatchStore(_ inner: MemoryTieredReadBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredReadBatchStore {
        return CachedTieredReadBatchStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered read batches. Empty fields match all.
    final class TieredReadBatchQuery {
        var country: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minRate: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredReadBatch) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredReadBatch]) -> [TieredReadBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredReadBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredReadBatches(_ store: any TieredReadBatchStore, query: TieredReadBatchQuery) -> [TieredReadBatch] {
        return query.apply(store.list())
    }
}
