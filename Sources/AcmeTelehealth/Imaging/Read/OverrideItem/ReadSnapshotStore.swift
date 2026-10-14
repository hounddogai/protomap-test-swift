import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read snapshots by code.
    protocol ReadSnapshotStore {
        func find(_ code: String) -> ReadSnapshot?
        func save(_ item: ReadSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [ReadSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadSnapshotStore: ReadSnapshotStore {
        var items: [String: ReadSnapshot]
        var order: [String]

        init(items: [String: ReadSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadSnapshot) {
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

        func list() -> [ReadSnapshot] {
            var out: [ReadSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadSnapshotStore() -> any ReadSnapshotStore {
        return MemoryReadSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadSnapshotStore: ReadSnapshotStore {
        var inner: MemoryReadSnapshotStore
        var cache: TTLCache<ReadSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadSnapshotStore, cache: TTLCache<ReadSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadSnapshot? {
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

        func save(_ item: ReadSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadSnapshot] {
            return inner.list()
        }
    }

    static func newCachedReadSnapshotStore(_ inner: MemoryReadSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadSnapshotStore {
        return CachedReadSnapshotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects read snapshots. Empty fields match all.
    final class ReadSnapshotQuery {
        var title: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRevision: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadSnapshot) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReadSnapshot]) -> [ReadSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadSnapshots(_ store: any ReadSnapshotStore, query: ReadSnapshotQuery) -> [ReadSnapshot] {
        return query.apply(store.list())
    }
}
