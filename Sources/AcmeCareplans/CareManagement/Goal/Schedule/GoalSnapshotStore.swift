import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal snapshots by code.
    protocol GoalSnapshotStore {
        func find(_ code: String) -> GoalSnapshot?
        func save(_ item: GoalSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [GoalSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalSnapshotStore: GoalSnapshotStore {
        var items: [String: GoalSnapshot]
        var order: [String]

        init(items: [String: GoalSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalSnapshot) {
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

        func list() -> [GoalSnapshot] {
            var out: [GoalSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalSnapshotStore() -> any GoalSnapshotStore {
        return MemoryGoalSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalSnapshotStore: GoalSnapshotStore {
        var inner: MemoryGoalSnapshotStore
        var cache: TTLCache<GoalSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalSnapshotStore, cache: TTLCache<GoalSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalSnapshot? {
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

        func save(_ item: GoalSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalSnapshot] {
            return inner.list()
        }
    }

    static func newCachedGoalSnapshotStore(_ inner: MemoryGoalSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalSnapshotStore {
        return CachedGoalSnapshotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal snapshots. Empty fields match all.
    final class GoalSnapshotQuery {
        var unit: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalSnapshot) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [GoalSnapshot]) -> [GoalSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalSnapshots(_ store: any GoalSnapshotStore, query: GoalSnapshotQuery) -> [GoalSnapshot] {
        return query.apply(store.list())
    }
}
