import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered study snapshots by code.
    protocol TieredStudySnapshotStore {
        func find(_ code: String) -> TieredStudySnapshot?
        func save(_ item: TieredStudySnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [TieredStudySnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredStudySnapshotStore: TieredStudySnapshotStore {
        var items: [String: TieredStudySnapshot]
        var order: [String]

        init(items: [String: TieredStudySnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredStudySnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredStudySnapshot) {
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

        func list() -> [TieredStudySnapshot] {
            var out: [TieredStudySnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredStudySnapshotStore() -> any TieredStudySnapshotStore {
        return MemoryTieredStudySnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredStudySnapshotStore: TieredStudySnapshotStore {
        var inner: MemoryTieredStudySnapshotStore
        var cache: TTLCache<TieredStudySnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredStudySnapshotStore, cache: TTLCache<TieredStudySnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredStudySnapshot? {
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

        func save(_ item: TieredStudySnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredStudySnapshot] {
            return inner.list()
        }
    }

    static func newCachedTieredStudySnapshotStore(_ inner: MemoryTieredStudySnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredStudySnapshotStore {
        return CachedTieredStudySnapshotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered study snapshots. Empty fields match all.
    final class TieredStudySnapshotQuery {
        var country: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minRefills: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredStudySnapshot) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredStudySnapshot]) -> [TieredStudySnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredStudySnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredStudySnapshots(_ store: any TieredStudySnapshotStore, query: TieredStudySnapshotQuery) -> [TieredStudySnapshot] {
        return query.apply(store.list())
    }
}
