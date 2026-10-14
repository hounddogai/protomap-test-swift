import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality batches by code.
    protocol ModalityBatchStore {
        func find(_ code: String) -> ModalityBatch?
        func save(_ item: ModalityBatch)
        func remove(_ code: String) -> Bool
        func list() -> [ModalityBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalityBatchStore: ModalityBatchStore {
        var items: [String: ModalityBatch]
        var order: [String]

        init(items: [String: ModalityBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalityBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalityBatch) {
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

        func list() -> [ModalityBatch] {
            var out: [ModalityBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalityBatchStore() -> any ModalityBatchStore {
        return MemoryModalityBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalityBatchStore: ModalityBatchStore {
        var inner: MemoryModalityBatchStore
        var cache: TTLCache<ModalityBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalityBatchStore, cache: TTLCache<ModalityBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalityBatch? {
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

        func save(_ item: ModalityBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalityBatch] {
            return inner.list()
        }
    }

    static func newCachedModalityBatchStore(_ inner: MemoryModalityBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalityBatchStore {
        return CachedModalityBatchStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality batches. Empty fields match all.
    final class ModalityBatchQuery {
        var facility: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minScore: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ModalityBatch) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [ModalityBatch]) -> [ModalityBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalityBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalityBatches(_ store: any ModalityBatchStore, query: ModalityBatchQuery) -> [ModalityBatch] {
        return query.apply(store.list())
    }
}
