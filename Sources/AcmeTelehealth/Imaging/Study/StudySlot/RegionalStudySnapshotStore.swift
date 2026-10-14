import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps regional study snapshots by code.
    protocol RegionalStudySnapshotStore {
        func find(_ code: String) -> RegionalStudySnapshot?
        func save(_ item: RegionalStudySnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalStudySnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalStudySnapshotStore: RegionalStudySnapshotStore {
        var items: [String: RegionalStudySnapshot]
        var order: [String]

        init(items: [String: RegionalStudySnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalStudySnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalStudySnapshot) {
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

        func list() -> [RegionalStudySnapshot] {
            var out: [RegionalStudySnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalStudySnapshotStore() -> any RegionalStudySnapshotStore {
        return MemoryRegionalStudySnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalStudySnapshotStore: RegionalStudySnapshotStore {
        var inner: MemoryRegionalStudySnapshotStore
        var cache: TTLCache<RegionalStudySnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalStudySnapshotStore, cache: TTLCache<RegionalStudySnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalStudySnapshot? {
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

        func save(_ item: RegionalStudySnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalStudySnapshot] {
            return inner.list()
        }
    }

    static func newCachedRegionalStudySnapshotStore(_ inner: MemoryRegionalStudySnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalStudySnapshotStore {
        return CachedRegionalStudySnapshotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional study snapshots. Empty fields match all.
    final class RegionalStudySnapshotQuery {
        var name: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalStudySnapshot) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalStudySnapshot]) -> [RegionalStudySnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalStudySnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalStudySnapshots(_ store: any RegionalStudySnapshotStore, query: RegionalStudySnapshotQuery) -> [RegionalStudySnapshot] {
        return query.apply(store.list())
    }
}
