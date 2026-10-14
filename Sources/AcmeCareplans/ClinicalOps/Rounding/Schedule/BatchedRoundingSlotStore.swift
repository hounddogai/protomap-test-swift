import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps batched rounding slots by code.
    protocol BatchedRoundingSlotStore {
        func find(_ code: String) -> BatchedRoundingSlot?
        func save(_ item: BatchedRoundingSlot)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedRoundingSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedRoundingSlotStore: BatchedRoundingSlotStore {
        var items: [String: BatchedRoundingSlot]
        var order: [String]

        init(items: [String: BatchedRoundingSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedRoundingSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedRoundingSlot) {
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

        func list() -> [BatchedRoundingSlot] {
            var out: [BatchedRoundingSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedRoundingSlotStore() -> any BatchedRoundingSlotStore {
        return MemoryBatchedRoundingSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedRoundingSlotStore: BatchedRoundingSlotStore {
        var inner: MemoryBatchedRoundingSlotStore
        var cache: TTLCache<BatchedRoundingSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedRoundingSlotStore, cache: TTLCache<BatchedRoundingSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedRoundingSlot? {
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

        func save(_ item: BatchedRoundingSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedRoundingSlot] {
            return inner.list()
        }
    }

    static func newCachedBatchedRoundingSlotStore(_ inner: MemoryBatchedRoundingSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedRoundingSlotStore {
        return CachedBatchedRoundingSlotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched rounding slots. Empty fields match all.
    final class BatchedRoundingSlotQuery {
        var source: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minRefills: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedRoundingSlot) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedRoundingSlot]) -> [BatchedRoundingSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedRoundingSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedRoundingSlots(_ store: any BatchedRoundingSlotStore, query: BatchedRoundingSlotQuery) -> [BatchedRoundingSlot] {
        return query.apply(store.list())
    }
}
