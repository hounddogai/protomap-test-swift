import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority snapshots by code.
    protocol PrioritySnapshotStore {
        func find(_ code: String) -> PrioritySnapshot?
        func save(_ item: PrioritySnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [PrioritySnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrioritySnapshotStore: PrioritySnapshotStore {
        var items: [String: PrioritySnapshot]
        var order: [String]

        init(items: [String: PrioritySnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrioritySnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrioritySnapshot) {
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

        func list() -> [PrioritySnapshot] {
            var out: [PrioritySnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrioritySnapshotStore() -> any PrioritySnapshotStore {
        return MemoryPrioritySnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrioritySnapshotStore: PrioritySnapshotStore {
        var inner: MemoryPrioritySnapshotStore
        var cache: TTLCache<PrioritySnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrioritySnapshotStore, cache: TTLCache<PrioritySnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrioritySnapshot? {
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

        func save(_ item: PrioritySnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrioritySnapshot] {
            return inner.list()
        }
    }

    static func newCachedPrioritySnapshotStore(_ inner: MemoryPrioritySnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrioritySnapshotStore {
        return CachedPrioritySnapshotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority snapshots. Empty fields match all.
    final class PrioritySnapshotQuery {
        var source: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrioritySnapshot) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrioritySnapshot]) -> [PrioritySnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrioritySnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrioritySnapshots(_ store: any PrioritySnapshotStore, query: PrioritySnapshotQuery) -> [PrioritySnapshot] {
        return query.apply(store.list())
    }
}
