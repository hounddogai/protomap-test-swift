import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen snapshots by code.
    protocol SpecimenSnapshotStore {
        func find(_ code: String) -> SpecimenSnapshot?
        func save(_ item: SpecimenSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenSnapshotStore: SpecimenSnapshotStore {
        var items: [String: SpecimenSnapshot]
        var order: [String]

        init(items: [String: SpecimenSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenSnapshot) {
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

        func list() -> [SpecimenSnapshot] {
            var out: [SpecimenSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenSnapshotStore() -> any SpecimenSnapshotStore {
        return MemorySpecimenSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenSnapshotStore: SpecimenSnapshotStore {
        var inner: MemorySpecimenSnapshotStore
        var cache: TTLCache<SpecimenSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenSnapshotStore, cache: TTLCache<SpecimenSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenSnapshot? {
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

        func save(_ item: SpecimenSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenSnapshot] {
            return inner.list()
        }
    }

    static func newCachedSpecimenSnapshotStore(_ inner: MemorySpecimenSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenSnapshotStore {
        return CachedSpecimenSnapshotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen snapshots. Empty fields match all.
    final class SpecimenSnapshotQuery {
        var unit: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenSnapshot) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SpecimenSnapshot]) -> [SpecimenSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenSnapshots(_ store: any SpecimenSnapshotStore, query: SpecimenSnapshotQuery) -> [SpecimenSnapshot] {
        return query.apply(store.list())
    }
}
