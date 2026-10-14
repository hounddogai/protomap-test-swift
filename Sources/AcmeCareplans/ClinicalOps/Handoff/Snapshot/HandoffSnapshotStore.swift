import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff snapshots by code.
    protocol HandoffSnapshotStore {
        func find(_ code: String) -> HandoffSnapshot?
        func save(_ item: HandoffSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffSnapshotStore: HandoffSnapshotStore {
        var items: [String: HandoffSnapshot]
        var order: [String]

        init(items: [String: HandoffSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffSnapshot) {
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

        func list() -> [HandoffSnapshot] {
            var out: [HandoffSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffSnapshotStore() -> any HandoffSnapshotStore {
        return MemoryHandoffSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffSnapshotStore: HandoffSnapshotStore {
        var inner: MemoryHandoffSnapshotStore
        var cache: TTLCache<HandoffSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffSnapshotStore, cache: TTLCache<HandoffSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffSnapshot? {
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

        func save(_ item: HandoffSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffSnapshot] {
            return inner.list()
        }
    }

    static func newCachedHandoffSnapshotStore(_ inner: MemoryHandoffSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffSnapshotStore {
        return CachedHandoffSnapshotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff snapshots. Empty fields match all.
    final class HandoffSnapshotQuery {
        var name: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffSnapshot) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [HandoffSnapshot]) -> [HandoffSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffSnapshots(_ store: any HandoffSnapshotStore, query: HandoffSnapshotQuery) -> [HandoffSnapshot] {
        return query.apply(store.list())
    }
}
