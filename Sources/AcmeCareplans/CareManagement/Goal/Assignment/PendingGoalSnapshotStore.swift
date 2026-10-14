import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps pending goal snapshots by code.
    protocol PendingGoalSnapshotStore {
        func find(_ code: String) -> PendingGoalSnapshot?
        func save(_ item: PendingGoalSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [PendingGoalSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingGoalSnapshotStore: PendingGoalSnapshotStore {
        var items: [String: PendingGoalSnapshot]
        var order: [String]

        init(items: [String: PendingGoalSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingGoalSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingGoalSnapshot) {
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

        func list() -> [PendingGoalSnapshot] {
            var out: [PendingGoalSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingGoalSnapshotStore() -> any PendingGoalSnapshotStore {
        return MemoryPendingGoalSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingGoalSnapshotStore: PendingGoalSnapshotStore {
        var inner: MemoryPendingGoalSnapshotStore
        var cache: TTLCache<PendingGoalSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingGoalSnapshotStore, cache: TTLCache<PendingGoalSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingGoalSnapshot? {
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

        func save(_ item: PendingGoalSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingGoalSnapshot] {
            return inner.list()
        }
    }

    static func newCachedPendingGoalSnapshotStore(_ inner: MemoryPendingGoalSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingGoalSnapshotStore {
        return CachedPendingGoalSnapshotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending goal snapshots. Empty fields match all.
    final class PendingGoalSnapshotQuery {
        var category: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingGoalSnapshot) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingGoalSnapshot]) -> [PendingGoalSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingGoalSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingGoalSnapshots(_ store: any PendingGoalSnapshotStore, query: PendingGoalSnapshotQuery) -> [PendingGoalSnapshot] {
        return query.apply(store.list())
    }
}
