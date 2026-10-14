import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority batches by code.
    protocol PriorityBatchStore {
        func find(_ code: String) -> PriorityBatch?
        func save(_ item: PriorityBatch)
        func remove(_ code: String) -> Bool
        func list() -> [PriorityBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPriorityBatchStore: PriorityBatchStore {
        var items: [String: PriorityBatch]
        var order: [String]

        init(items: [String: PriorityBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PriorityBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PriorityBatch) {
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

        func list() -> [PriorityBatch] {
            var out: [PriorityBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPriorityBatchStore() -> any PriorityBatchStore {
        return MemoryPriorityBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPriorityBatchStore: PriorityBatchStore {
        var inner: MemoryPriorityBatchStore
        var cache: TTLCache<PriorityBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryPriorityBatchStore, cache: TTLCache<PriorityBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PriorityBatch? {
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

        func save(_ item: PriorityBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PriorityBatch] {
            return inner.list()
        }
    }

    static func newCachedPriorityBatchStore(_ inner: MemoryPriorityBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PriorityBatchStore {
        return CachedPriorityBatchStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority batches. Empty fields match all.
    final class PriorityBatchQuery {
        var region: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minScore: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PriorityBatch) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [PriorityBatch]) -> [PriorityBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PriorityBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPriorityBatches(_ store: any PriorityBatchStore, query: PriorityBatchQuery) -> [PriorityBatch] {
        return query.apply(store.list())
    }
}
