import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps batched bed board slots by code.
    protocol BatchedBedBoardSlotStore {
        func find(_ code: String) -> BatchedBedBoardSlot?
        func save(_ item: BatchedBedBoardSlot)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedBedBoardSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedBedBoardSlotStore: BatchedBedBoardSlotStore {
        var items: [String: BatchedBedBoardSlot]
        var order: [String]

        init(items: [String: BatchedBedBoardSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedBedBoardSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedBedBoardSlot) {
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

        func list() -> [BatchedBedBoardSlot] {
            var out: [BatchedBedBoardSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedBedBoardSlotStore() -> any BatchedBedBoardSlotStore {
        return MemoryBatchedBedBoardSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedBedBoardSlotStore: BatchedBedBoardSlotStore {
        var inner: MemoryBatchedBedBoardSlotStore
        var cache: TTLCache<BatchedBedBoardSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedBedBoardSlotStore, cache: TTLCache<BatchedBedBoardSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedBedBoardSlot? {
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

        func save(_ item: BatchedBedBoardSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedBedBoardSlot] {
            return inner.list()
        }
    }

    static func newCachedBatchedBedBoardSlotStore(_ inner: MemoryBatchedBedBoardSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedBedBoardSlotStore {
        return CachedBatchedBedBoardSlotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched bed board slots. Empty fields match all.
    final class BatchedBedBoardSlotQuery {
        var title: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedBedBoardSlot) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedBedBoardSlot]) -> [BatchedBedBoardSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedBedBoardSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedBedBoardSlots(_ store: any BatchedBedBoardSlotStore, query: BatchedBedBoardSlotQuery) -> [BatchedBedBoardSlot] {
        return query.apply(store.list())
    }
}
