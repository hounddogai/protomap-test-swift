import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall snapshots by code.
    protocol RecallSnapshotStore {
        func find(_ code: String) -> RecallSnapshot?
        func save(_ item: RecallSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [RecallSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallSnapshotStore: RecallSnapshotStore {
        var items: [String: RecallSnapshot]
        var order: [String]

        init(items: [String: RecallSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallSnapshot) {
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

        func list() -> [RecallSnapshot] {
            var out: [RecallSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallSnapshotStore() -> any RecallSnapshotStore {
        return MemoryRecallSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallSnapshotStore: RecallSnapshotStore {
        var inner: MemoryRecallSnapshotStore
        var cache: TTLCache<RecallSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallSnapshotStore, cache: TTLCache<RecallSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallSnapshot? {
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

        func save(_ item: RecallSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallSnapshot] {
            return inner.list()
        }
    }

    static func newCachedRecallSnapshotStore(_ inner: MemoryRecallSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallSnapshotStore {
        return CachedRecallSnapshotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall snapshots. Empty fields match all.
    final class RecallSnapshotQuery {
        var region: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minRatio: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallSnapshot) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RecallSnapshot]) -> [RecallSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallSnapshots(_ store: any RecallSnapshotStore, query: RecallSnapshotQuery) -> [RecallSnapshot] {
        return query.apply(store.list())
    }
}
