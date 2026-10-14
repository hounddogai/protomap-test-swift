import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime snapshots by code.
    protocol OvertimeSnapshotStore {
        func find(_ code: String) -> OvertimeSnapshot?
        func save(_ item: OvertimeSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeSnapshotStore: OvertimeSnapshotStore {
        var items: [String: OvertimeSnapshot]
        var order: [String]

        init(items: [String: OvertimeSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeSnapshot) {
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

        func list() -> [OvertimeSnapshot] {
            var out: [OvertimeSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeSnapshotStore() -> any OvertimeSnapshotStore {
        return MemoryOvertimeSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeSnapshotStore: OvertimeSnapshotStore {
        var inner: MemoryOvertimeSnapshotStore
        var cache: TTLCache<OvertimeSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeSnapshotStore, cache: TTLCache<OvertimeSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeSnapshot? {
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

        func save(_ item: OvertimeSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeSnapshot] {
            return inner.list()
        }
    }

    static func newCachedOvertimeSnapshotStore(_ inner: MemoryOvertimeSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeSnapshotStore {
        return CachedOvertimeSnapshotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime snapshots. Empty fields match all.
    final class OvertimeSnapshotQuery {
        var segment: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeSnapshot) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OvertimeSnapshot]) -> [OvertimeSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeSnapshots(_ store: any OvertimeSnapshotStore, query: OvertimeSnapshotQuery) -> [OvertimeSnapshot] {
        return query.apply(store.list())
    }
}
