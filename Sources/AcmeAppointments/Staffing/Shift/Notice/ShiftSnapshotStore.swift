import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift snapshots by code.
    protocol ShiftSnapshotStore {
        func find(_ code: String) -> ShiftSnapshot?
        func save(_ item: ShiftSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftSnapshotStore: ShiftSnapshotStore {
        var items: [String: ShiftSnapshot]
        var order: [String]

        init(items: [String: ShiftSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftSnapshot) {
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

        func list() -> [ShiftSnapshot] {
            var out: [ShiftSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftSnapshotStore() -> any ShiftSnapshotStore {
        return MemoryShiftSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftSnapshotStore: ShiftSnapshotStore {
        var inner: MemoryShiftSnapshotStore
        var cache: TTLCache<ShiftSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftSnapshotStore, cache: TTLCache<ShiftSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftSnapshot? {
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

        func save(_ item: ShiftSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftSnapshot] {
            return inner.list()
        }
    }

    static func newCachedShiftSnapshotStore(_ inner: MemoryShiftSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftSnapshotStore {
        return CachedShiftSnapshotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift snapshots. Empty fields match all.
    final class ShiftSnapshotQuery {
        var name: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minSequence: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftSnapshot) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ShiftSnapshot]) -> [ShiftSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftSnapshots(_ store: any ShiftSnapshotStore, query: ShiftSnapshotQuery) -> [ShiftSnapshot] {
        return query.apply(store.list())
    }
}
