import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps default inventory batches by code.
    protocol DefaultInventoryBatchStore {
        func find(_ code: String) -> DefaultInventoryBatch?
        func save(_ item: DefaultInventoryBatch)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultInventoryBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultInventoryBatchStore: DefaultInventoryBatchStore {
        var items: [String: DefaultInventoryBatch]
        var order: [String]

        init(items: [String: DefaultInventoryBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultInventoryBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultInventoryBatch) {
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

        func list() -> [DefaultInventoryBatch] {
            var out: [DefaultInventoryBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultInventoryBatchStore() -> any DefaultInventoryBatchStore {
        return MemoryDefaultInventoryBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultInventoryBatchStore: DefaultInventoryBatchStore {
        var inner: MemoryDefaultInventoryBatchStore
        var cache: TTLCache<DefaultInventoryBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultInventoryBatchStore, cache: TTLCache<DefaultInventoryBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultInventoryBatch? {
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

        func save(_ item: DefaultInventoryBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultInventoryBatch] {
            return inner.list()
        }
    }

    static func newCachedDefaultInventoryBatchStore(_ inner: MemoryDefaultInventoryBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultInventoryBatchStore {
        return CachedDefaultInventoryBatchStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default inventory batches. Empty fields match all.
    final class DefaultInventoryBatchQuery {
        var title: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minScore: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultInventoryBatch) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultInventoryBatch]) -> [DefaultInventoryBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultInventoryBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultInventoryBatches(_ store: any DefaultInventoryBatchStore, query: DefaultInventoryBatchQuery) -> [DefaultInventoryBatch] {
        return query.apply(store.list())
    }
}
