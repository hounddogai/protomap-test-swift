import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps batched slot snapshots by code.
    protocol BatchedSlotSnapshotStore {
        func find(_ code: String) -> BatchedSlotSnapshot?
        func save(_ item: BatchedSlotSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedSlotSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedSlotSnapshotStore: BatchedSlotSnapshotStore {
        var items: [String: BatchedSlotSnapshot]
        var order: [String]

        init(items: [String: BatchedSlotSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedSlotSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedSlotSnapshot) {
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

        func list() -> [BatchedSlotSnapshot] {
            var out: [BatchedSlotSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedSlotSnapshotStore() -> any BatchedSlotSnapshotStore {
        return MemoryBatchedSlotSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedSlotSnapshotStore: BatchedSlotSnapshotStore {
        var inner: MemoryBatchedSlotSnapshotStore
        var cache: TTLCache<BatchedSlotSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedSlotSnapshotStore, cache: TTLCache<BatchedSlotSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedSlotSnapshot? {
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

        func save(_ item: BatchedSlotSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedSlotSnapshot] {
            return inner.list()
        }
    }

    static func newCachedBatchedSlotSnapshotStore(_ inner: MemoryBatchedSlotSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedSlotSnapshotStore {
        return CachedBatchedSlotSnapshotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched slot snapshots. Empty fields match all.
    final class BatchedSlotSnapshotQuery {
        var channel: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minAmount: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedSlotSnapshot) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedSlotSnapshot]) -> [BatchedSlotSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedSlotSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedSlotSnapshots(_ store: any BatchedSlotSnapshotStore, query: BatchedSlotSnapshotQuery) -> [BatchedSlotSnapshot] {
        return query.apply(store.list())
    }
}
