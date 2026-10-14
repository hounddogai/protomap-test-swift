import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps default order set batches by code.
    protocol DefaultOrderSetBatchStore {
        func find(_ code: String) -> DefaultOrderSetBatch?
        func save(_ item: DefaultOrderSetBatch)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultOrderSetBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultOrderSetBatchStore: DefaultOrderSetBatchStore {
        var items: [String: DefaultOrderSetBatch]
        var order: [String]

        init(items: [String: DefaultOrderSetBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultOrderSetBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultOrderSetBatch) {
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

        func list() -> [DefaultOrderSetBatch] {
            var out: [DefaultOrderSetBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultOrderSetBatchStore() -> any DefaultOrderSetBatchStore {
        return MemoryDefaultOrderSetBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultOrderSetBatchStore: DefaultOrderSetBatchStore {
        var inner: MemoryDefaultOrderSetBatchStore
        var cache: TTLCache<DefaultOrderSetBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultOrderSetBatchStore, cache: TTLCache<DefaultOrderSetBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultOrderSetBatch? {
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

        func save(_ item: DefaultOrderSetBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultOrderSetBatch] {
            return inner.list()
        }
    }

    static func newCachedDefaultOrderSetBatchStore(_ inner: MemoryDefaultOrderSetBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultOrderSetBatchStore {
        return CachedDefaultOrderSetBatchStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default order set batches. Empty fields match all.
    final class DefaultOrderSetBatchQuery {
        var channel: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultOrderSetBatch) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [DefaultOrderSetBatch]) -> [DefaultOrderSetBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultOrderSetBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultOrderSetBatches(_ store: any DefaultOrderSetBatchStore, query: DefaultOrderSetBatchQuery) -> [DefaultOrderSetBatch] {
        return query.apply(store.list())
    }
}
