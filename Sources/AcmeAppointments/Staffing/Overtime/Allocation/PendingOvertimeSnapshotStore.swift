import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps pending overtime snapshots by code.
    protocol PendingOvertimeSnapshotStore {
        func find(_ code: String) -> PendingOvertimeSnapshot?
        func save(_ item: PendingOvertimeSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [PendingOvertimeSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingOvertimeSnapshotStore: PendingOvertimeSnapshotStore {
        var items: [String: PendingOvertimeSnapshot]
        var order: [String]

        init(items: [String: PendingOvertimeSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingOvertimeSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingOvertimeSnapshot) {
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

        func list() -> [PendingOvertimeSnapshot] {
            var out: [PendingOvertimeSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingOvertimeSnapshotStore() -> any PendingOvertimeSnapshotStore {
        return MemoryPendingOvertimeSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingOvertimeSnapshotStore: PendingOvertimeSnapshotStore {
        var inner: MemoryPendingOvertimeSnapshotStore
        var cache: TTLCache<PendingOvertimeSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingOvertimeSnapshotStore, cache: TTLCache<PendingOvertimeSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingOvertimeSnapshot? {
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

        func save(_ item: PendingOvertimeSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingOvertimeSnapshot] {
            return inner.list()
        }
    }

    static func newCachedPendingOvertimeSnapshotStore(_ inner: MemoryPendingOvertimeSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingOvertimeSnapshotStore {
        return CachedPendingOvertimeSnapshotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending overtime snapshots. Empty fields match all.
    final class PendingOvertimeSnapshotQuery {
        var title: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingOvertimeSnapshot) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingOvertimeSnapshot]) -> [PendingOvertimeSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingOvertimeSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingOvertimeSnapshots(_ store: any PendingOvertimeSnapshotStore, query: PendingOvertimeSnapshotQuery) -> [PendingOvertimeSnapshot] {
        return query.apply(store.list())
    }
}
