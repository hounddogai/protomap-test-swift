import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps strict modality snapshots by code.
    protocol StrictModalitySnapshotStore {
        func find(_ code: String) -> StrictModalitySnapshot?
        func save(_ item: StrictModalitySnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [StrictModalitySnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictModalitySnapshotStore: StrictModalitySnapshotStore {
        var items: [String: StrictModalitySnapshot]
        var order: [String]

        init(items: [String: StrictModalitySnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictModalitySnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictModalitySnapshot) {
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

        func list() -> [StrictModalitySnapshot] {
            var out: [StrictModalitySnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictModalitySnapshotStore() -> any StrictModalitySnapshotStore {
        return MemoryStrictModalitySnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictModalitySnapshotStore: StrictModalitySnapshotStore {
        var inner: MemoryStrictModalitySnapshotStore
        var cache: TTLCache<StrictModalitySnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictModalitySnapshotStore, cache: TTLCache<StrictModalitySnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictModalitySnapshot? {
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

        func save(_ item: StrictModalitySnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictModalitySnapshot] {
            return inner.list()
        }
    }

    static func newCachedStrictModalitySnapshotStore(_ inner: MemoryStrictModalitySnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictModalitySnapshotStore {
        return CachedStrictModalitySnapshotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict modality snapshots. Empty fields match all.
    final class StrictModalitySnapshotQuery {
        var category: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictModalitySnapshot) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [StrictModalitySnapshot]) -> [StrictModalitySnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictModalitySnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictModalitySnapshots(_ store: any StrictModalitySnapshotStore, query: StrictModalitySnapshotQuery) -> [StrictModalitySnapshot] {
        return query.apply(store.list())
    }
}
