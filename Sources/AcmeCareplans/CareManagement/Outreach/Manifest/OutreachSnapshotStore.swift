import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach snapshots by code.
    protocol OutreachSnapshotStore {
        func find(_ code: String) -> OutreachSnapshot?
        func save(_ item: OutreachSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachSnapshotStore: OutreachSnapshotStore {
        var items: [String: OutreachSnapshot]
        var order: [String]

        init(items: [String: OutreachSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachSnapshot) {
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

        func list() -> [OutreachSnapshot] {
            var out: [OutreachSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachSnapshotStore() -> any OutreachSnapshotStore {
        return MemoryOutreachSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachSnapshotStore: OutreachSnapshotStore {
        var inner: MemoryOutreachSnapshotStore
        var cache: TTLCache<OutreachSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachSnapshotStore, cache: TTLCache<OutreachSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachSnapshot? {
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

        func save(_ item: OutreachSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachSnapshot] {
            return inner.list()
        }
    }

    static func newCachedOutreachSnapshotStore(_ inner: MemoryOutreachSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachSnapshotStore {
        return CachedOutreachSnapshotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach snapshots. Empty fields match all.
    final class OutreachSnapshotQuery {
        var ward: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minSequence: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachSnapshot) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [OutreachSnapshot]) -> [OutreachSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachSnapshots(_ store: any OutreachSnapshotStore, query: OutreachSnapshotQuery) -> [OutreachSnapshot] {
        return query.apply(store.list())
    }
}
