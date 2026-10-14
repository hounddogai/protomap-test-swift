import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps strict read snapshots by code.
    protocol StrictReadSnapshotStore {
        func find(_ code: String) -> StrictReadSnapshot?
        func save(_ item: StrictReadSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [StrictReadSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictReadSnapshotStore: StrictReadSnapshotStore {
        var items: [String: StrictReadSnapshot]
        var order: [String]

        init(items: [String: StrictReadSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictReadSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictReadSnapshot) {
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

        func list() -> [StrictReadSnapshot] {
            var out: [StrictReadSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictReadSnapshotStore() -> any StrictReadSnapshotStore {
        return MemoryStrictReadSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictReadSnapshotStore: StrictReadSnapshotStore {
        var inner: MemoryStrictReadSnapshotStore
        var cache: TTLCache<StrictReadSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictReadSnapshotStore, cache: TTLCache<StrictReadSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictReadSnapshot? {
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

        func save(_ item: StrictReadSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictReadSnapshot] {
            return inner.list()
        }
    }

    static func newCachedStrictReadSnapshotStore(_ inner: MemoryStrictReadSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictReadSnapshotStore {
        return CachedStrictReadSnapshotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict read snapshots. Empty fields match all.
    final class StrictReadSnapshotQuery {
        var title: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minPriority: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictReadSnapshot) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictReadSnapshot]) -> [StrictReadSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictReadSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictReadSnapshots(_ store: any StrictReadSnapshotStore, query: StrictReadSnapshotQuery) -> [StrictReadSnapshot] {
        return query.apply(store.list())
    }
}
