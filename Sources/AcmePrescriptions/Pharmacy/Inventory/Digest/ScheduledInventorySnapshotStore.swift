import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps scheduled inventory snapshots by code.
    protocol ScheduledInventorySnapshotStore {
        func find(_ code: String) -> ScheduledInventorySnapshot?
        func save(_ item: ScheduledInventorySnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledInventorySnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledInventorySnapshotStore: ScheduledInventorySnapshotStore {
        var items: [String: ScheduledInventorySnapshot]
        var order: [String]

        init(items: [String: ScheduledInventorySnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledInventorySnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledInventorySnapshot) {
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

        func list() -> [ScheduledInventorySnapshot] {
            var out: [ScheduledInventorySnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledInventorySnapshotStore() -> any ScheduledInventorySnapshotStore {
        return MemoryScheduledInventorySnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledInventorySnapshotStore: ScheduledInventorySnapshotStore {
        var inner: MemoryScheduledInventorySnapshotStore
        var cache: TTLCache<ScheduledInventorySnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledInventorySnapshotStore, cache: TTLCache<ScheduledInventorySnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledInventorySnapshot? {
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

        func save(_ item: ScheduledInventorySnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledInventorySnapshot] {
            return inner.list()
        }
    }

    static func newCachedScheduledInventorySnapshotStore(_ inner: MemoryScheduledInventorySnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledInventorySnapshotStore {
        return CachedScheduledInventorySnapshotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled inventory snapshots. Empty fields match all.
    final class ScheduledInventorySnapshotQuery {
        var title: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledInventorySnapshot) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledInventorySnapshot]) -> [ScheduledInventorySnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledInventorySnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledInventorySnapshots(_ store: any ScheduledInventorySnapshotStore, query: ScheduledInventorySnapshotQuery) -> [ScheduledInventorySnapshot] {
        return query.apply(store.list())
    }
}
