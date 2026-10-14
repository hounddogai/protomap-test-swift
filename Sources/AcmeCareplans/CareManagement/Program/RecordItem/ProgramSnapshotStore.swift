import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program snapshots by code.
    protocol ProgramSnapshotStore {
        func find(_ code: String) -> ProgramSnapshot?
        func save(_ item: ProgramSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramSnapshotStore: ProgramSnapshotStore {
        var items: [String: ProgramSnapshot]
        var order: [String]

        init(items: [String: ProgramSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramSnapshot) {
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

        func list() -> [ProgramSnapshot] {
            var out: [ProgramSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramSnapshotStore() -> any ProgramSnapshotStore {
        return MemoryProgramSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramSnapshotStore: ProgramSnapshotStore {
        var inner: MemoryProgramSnapshotStore
        var cache: TTLCache<ProgramSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramSnapshotStore, cache: TTLCache<ProgramSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramSnapshot? {
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

        func save(_ item: ProgramSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramSnapshot] {
            return inner.list()
        }
    }

    static func newCachedProgramSnapshotStore(_ inner: MemoryProgramSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramSnapshotStore {
        return CachedProgramSnapshotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program snapshots. Empty fields match all.
    final class ProgramSnapshotQuery {
        var unit: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramSnapshot) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [ProgramSnapshot]) -> [ProgramSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramSnapshots(_ store: any ProgramSnapshotStore, query: ProgramSnapshotQuery) -> [ProgramSnapshot] {
        return query.apply(store.list())
    }
}
