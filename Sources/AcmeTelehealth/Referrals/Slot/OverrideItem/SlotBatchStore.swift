import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps slot batches by code.
    protocol SlotBatchStore {
        func find(_ code: String) -> SlotBatch?
        func save(_ item: SlotBatch)
        func remove(_ code: String) -> Bool
        func list() -> [SlotBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySlotBatchStore: SlotBatchStore {
        var items: [String: SlotBatch]
        var order: [String]

        init(items: [String: SlotBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SlotBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SlotBatch) {
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

        func list() -> [SlotBatch] {
            var out: [SlotBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySlotBatchStore() -> any SlotBatchStore {
        return MemorySlotBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSlotBatchStore: SlotBatchStore {
        var inner: MemorySlotBatchStore
        var cache: TTLCache<SlotBatch>
        var hits: Int
        var misses: Int

        init(inner: MemorySlotBatchStore, cache: TTLCache<SlotBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SlotBatch? {
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

        func save(_ item: SlotBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SlotBatch] {
            return inner.list()
        }
    }

    static func newCachedSlotBatchStore(_ inner: MemorySlotBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SlotBatchStore {
        return CachedSlotBatchStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects slot batches. Empty fields match all.
    final class SlotBatchQuery {
        var source: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SlotBatch) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SlotBatch]) -> [SlotBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SlotBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSlotBatches(_ store: any SlotBatchStore, query: SlotBatchQuery) -> [SlotBatch] {
        return query.apply(store.list())
    }
}
