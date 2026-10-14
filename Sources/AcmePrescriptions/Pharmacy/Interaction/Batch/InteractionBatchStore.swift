import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction batches by code.
    protocol InteractionBatchStore {
        func find(_ code: String) -> InteractionBatch?
        func save(_ item: InteractionBatch)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionBatchStore: InteractionBatchStore {
        var items: [String: InteractionBatch]
        var order: [String]

        init(items: [String: InteractionBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionBatch) {
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

        func list() -> [InteractionBatch] {
            var out: [InteractionBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionBatchStore() -> any InteractionBatchStore {
        return MemoryInteractionBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionBatchStore: InteractionBatchStore {
        var inner: MemoryInteractionBatchStore
        var cache: TTLCache<InteractionBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionBatchStore, cache: TTLCache<InteractionBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionBatch? {
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

        func save(_ item: InteractionBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionBatch] {
            return inner.list()
        }
    }

    static func newCachedInteractionBatchStore(_ inner: MemoryInteractionBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionBatchStore {
        return CachedInteractionBatchStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction batches. Empty fields match all.
    final class InteractionBatchQuery {
        var ward: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionBatch) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionBatch]) -> [InteractionBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionBatches(_ store: any InteractionBatchStore, query: InteractionBatchQuery) -> [InteractionBatch] {
        return query.apply(store.list())
    }
}
