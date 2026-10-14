import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps capped recall snapshots by code.
    protocol CappedRecallSnapshotStore {
        func find(_ code: String) -> CappedRecallSnapshot?
        func save(_ item: CappedRecallSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [CappedRecallSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedRecallSnapshotStore: CappedRecallSnapshotStore {
        var items: [String: CappedRecallSnapshot]
        var order: [String]

        init(items: [String: CappedRecallSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedRecallSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedRecallSnapshot) {
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

        func list() -> [CappedRecallSnapshot] {
            var out: [CappedRecallSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedRecallSnapshotStore() -> any CappedRecallSnapshotStore {
        return MemoryCappedRecallSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedRecallSnapshotStore: CappedRecallSnapshotStore {
        var inner: MemoryCappedRecallSnapshotStore
        var cache: TTLCache<CappedRecallSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedRecallSnapshotStore, cache: TTLCache<CappedRecallSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedRecallSnapshot? {
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

        func save(_ item: CappedRecallSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedRecallSnapshot] {
            return inner.list()
        }
    }

    static func newCachedCappedRecallSnapshotStore(_ inner: MemoryCappedRecallSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedRecallSnapshotStore {
        return CachedCappedRecallSnapshotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped recall snapshots. Empty fields match all.
    final class CappedRecallSnapshotQuery {
        var name: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedRecallSnapshot) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedRecallSnapshot]) -> [CappedRecallSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedRecallSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedRecallSnapshots(_ store: any CappedRecallSnapshotStore, query: CappedRecallSnapshotQuery) -> [CappedRecallSnapshot] {
        return query.apply(store.list())
    }
}
