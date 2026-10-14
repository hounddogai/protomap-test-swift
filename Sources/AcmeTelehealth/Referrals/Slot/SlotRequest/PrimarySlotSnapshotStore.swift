import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps primary slot snapshots by code.
    protocol PrimarySlotSnapshotStore {
        func find(_ code: String) -> PrimarySlotSnapshot?
        func save(_ item: PrimarySlotSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [PrimarySlotSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimarySlotSnapshotStore: PrimarySlotSnapshotStore {
        var items: [String: PrimarySlotSnapshot]
        var order: [String]

        init(items: [String: PrimarySlotSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimarySlotSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimarySlotSnapshot) {
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

        func list() -> [PrimarySlotSnapshot] {
            var out: [PrimarySlotSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimarySlotSnapshotStore() -> any PrimarySlotSnapshotStore {
        return MemoryPrimarySlotSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimarySlotSnapshotStore: PrimarySlotSnapshotStore {
        var inner: MemoryPrimarySlotSnapshotStore
        var cache: TTLCache<PrimarySlotSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimarySlotSnapshotStore, cache: TTLCache<PrimarySlotSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimarySlotSnapshot? {
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

        func save(_ item: PrimarySlotSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimarySlotSnapshot] {
            return inner.list()
        }
    }

    static func newCachedPrimarySlotSnapshotStore(_ inner: MemoryPrimarySlotSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimarySlotSnapshotStore {
        return CachedPrimarySlotSnapshotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary slot snapshots. Empty fields match all.
    final class PrimarySlotSnapshotQuery {
        var unit: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimarySlotSnapshot) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimarySlotSnapshot]) -> [PrimarySlotSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimarySlotSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimarySlotSnapshots(_ store: any PrimarySlotSnapshotStore, query: PrimarySlotSnapshotQuery) -> [PrimarySlotSnapshot] {
        return query.apply(store.list())
    }
}
