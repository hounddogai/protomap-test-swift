import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps batched authorization snapshots by code.
    protocol BatchedAuthorizationSnapshotStore {
        func find(_ code: String) -> BatchedAuthorizationSnapshot?
        func save(_ item: BatchedAuthorizationSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedAuthorizationSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedAuthorizationSnapshotStore: BatchedAuthorizationSnapshotStore {
        var items: [String: BatchedAuthorizationSnapshot]
        var order: [String]

        init(items: [String: BatchedAuthorizationSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedAuthorizationSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedAuthorizationSnapshot) {
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

        func list() -> [BatchedAuthorizationSnapshot] {
            var out: [BatchedAuthorizationSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedAuthorizationSnapshotStore() -> any BatchedAuthorizationSnapshotStore {
        return MemoryBatchedAuthorizationSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedAuthorizationSnapshotStore: BatchedAuthorizationSnapshotStore {
        var inner: MemoryBatchedAuthorizationSnapshotStore
        var cache: TTLCache<BatchedAuthorizationSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedAuthorizationSnapshotStore, cache: TTLCache<BatchedAuthorizationSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedAuthorizationSnapshot? {
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

        func save(_ item: BatchedAuthorizationSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedAuthorizationSnapshot] {
            return inner.list()
        }
    }

    static func newCachedBatchedAuthorizationSnapshotStore(_ inner: MemoryBatchedAuthorizationSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedAuthorizationSnapshotStore {
        return CachedBatchedAuthorizationSnapshotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched authorization snapshots. Empty fields match all.
    final class BatchedAuthorizationSnapshotQuery {
        var title: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minScore: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedAuthorizationSnapshot) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [BatchedAuthorizationSnapshot]) -> [BatchedAuthorizationSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedAuthorizationSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedAuthorizationSnapshots(_ store: any BatchedAuthorizationSnapshotStore, query: BatchedAuthorizationSnapshotQuery) -> [BatchedAuthorizationSnapshot] {
        return query.apply(store.list())
    }
}
