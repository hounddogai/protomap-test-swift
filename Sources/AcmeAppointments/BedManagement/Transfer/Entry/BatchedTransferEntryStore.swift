import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps batched transfer entries by code.
    protocol BatchedTransferEntryStore {
        func find(_ code: String) -> BatchedTransferEntry?
        func save(_ item: BatchedTransferEntry)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedTransferEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedTransferEntryStore: BatchedTransferEntryStore {
        var items: [String: BatchedTransferEntry]
        var order: [String]

        init(items: [String: BatchedTransferEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedTransferEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedTransferEntry) {
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

        func list() -> [BatchedTransferEntry] {
            var out: [BatchedTransferEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedTransferEntryStore() -> any BatchedTransferEntryStore {
        return MemoryBatchedTransferEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedTransferEntryStore: BatchedTransferEntryStore {
        var inner: MemoryBatchedTransferEntryStore
        var cache: TTLCache<BatchedTransferEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedTransferEntryStore, cache: TTLCache<BatchedTransferEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedTransferEntry? {
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

        func save(_ item: BatchedTransferEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedTransferEntry] {
            return inner.list()
        }
    }

    static func newCachedBatchedTransferEntryStore(_ inner: MemoryBatchedTransferEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedTransferEntryStore {
        return CachedBatchedTransferEntryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched transfer entries. Empty fields match all.
    final class BatchedTransferEntryQuery {
        var channel: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedTransferEntry) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedTransferEntry]) -> [BatchedTransferEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedTransferEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedTransferEntries(_ store: any BatchedTransferEntryStore, query: BatchedTransferEntryQuery) -> [BatchedTransferEntry] {
        return query.apply(store.list())
    }
}
