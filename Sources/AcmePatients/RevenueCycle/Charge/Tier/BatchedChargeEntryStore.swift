import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps batched charge entries by code.
    protocol BatchedChargeEntryStore {
        func find(_ code: String) -> BatchedChargeEntry?
        func save(_ item: BatchedChargeEntry)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedChargeEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedChargeEntryStore: BatchedChargeEntryStore {
        var items: [String: BatchedChargeEntry]
        var order: [String]

        init(items: [String: BatchedChargeEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedChargeEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedChargeEntry) {
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

        func list() -> [BatchedChargeEntry] {
            var out: [BatchedChargeEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedChargeEntryStore() -> any BatchedChargeEntryStore {
        return MemoryBatchedChargeEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedChargeEntryStore: BatchedChargeEntryStore {
        var inner: MemoryBatchedChargeEntryStore
        var cache: TTLCache<BatchedChargeEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedChargeEntryStore, cache: TTLCache<BatchedChargeEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedChargeEntry? {
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

        func save(_ item: BatchedChargeEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedChargeEntry] {
            return inner.list()
        }
    }

    static func newCachedBatchedChargeEntryStore(_ inner: MemoryBatchedChargeEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedChargeEntryStore {
        return CachedBatchedChargeEntryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched charge entries. Empty fields match all.
    final class BatchedChargeEntryQuery {
        var label: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedChargeEntry) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedChargeEntry]) -> [BatchedChargeEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedChargeEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedChargeEntries(_ store: any BatchedChargeEntryStore, query: BatchedChargeEntryQuery) -> [BatchedChargeEntry] {
        return query.apply(store.list())
    }
}
