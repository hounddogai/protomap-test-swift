import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool batches by code.
    protocol FloatPoolBatchStore {
        func find(_ code: String) -> FloatPoolBatch?
        func save(_ item: FloatPoolBatch)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolBatchStore: FloatPoolBatchStore {
        var items: [String: FloatPoolBatch]
        var order: [String]

        init(items: [String: FloatPoolBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolBatch) {
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

        func list() -> [FloatPoolBatch] {
            var out: [FloatPoolBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolBatchStore() -> any FloatPoolBatchStore {
        return MemoryFloatPoolBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolBatchStore: FloatPoolBatchStore {
        var inner: MemoryFloatPoolBatchStore
        var cache: TTLCache<FloatPoolBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolBatchStore, cache: TTLCache<FloatPoolBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolBatch? {
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

        func save(_ item: FloatPoolBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolBatch] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolBatchStore(_ inner: MemoryFloatPoolBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolBatchStore {
        return CachedFloatPoolBatchStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool batches. Empty fields match all.
    final class FloatPoolBatchQuery {
        var facility: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolBatch) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolBatch]) -> [FloatPoolBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolBatches(_ store: any FloatPoolBatchStore, query: FloatPoolBatchQuery) -> [FloatPoolBatch] {
        return query.apply(store.list())
    }
}
