import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps strict study batches by code.
    protocol StrictStudyBatchStore {
        func find(_ code: String) -> StrictStudyBatch?
        func save(_ item: StrictStudyBatch)
        func remove(_ code: String) -> Bool
        func list() -> [StrictStudyBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictStudyBatchStore: StrictStudyBatchStore {
        var items: [String: StrictStudyBatch]
        var order: [String]

        init(items: [String: StrictStudyBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictStudyBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictStudyBatch) {
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

        func list() -> [StrictStudyBatch] {
            var out: [StrictStudyBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictStudyBatchStore() -> any StrictStudyBatchStore {
        return MemoryStrictStudyBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictStudyBatchStore: StrictStudyBatchStore {
        var inner: MemoryStrictStudyBatchStore
        var cache: TTLCache<StrictStudyBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictStudyBatchStore, cache: TTLCache<StrictStudyBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictStudyBatch? {
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

        func save(_ item: StrictStudyBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictStudyBatch] {
            return inner.list()
        }
    }

    static func newCachedStrictStudyBatchStore(_ inner: MemoryStrictStudyBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictStudyBatchStore {
        return CachedStrictStudyBatchStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict study batches. Empty fields match all.
    final class StrictStudyBatchQuery {
        var title: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minWeight: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictStudyBatch) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictStudyBatch]) -> [StrictStudyBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictStudyBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictStudyBatches(_ store: any StrictStudyBatchStore, query: StrictStudyBatchQuery) -> [StrictStudyBatch] {
        return query.apply(store.list())
    }
}
