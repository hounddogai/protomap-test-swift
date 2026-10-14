import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps manual inventory snapshots by code.
    protocol ManualInventorySnapshotStore {
        func find(_ code: String) -> ManualInventorySnapshot?
        func save(_ item: ManualInventorySnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [ManualInventorySnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualInventorySnapshotStore: ManualInventorySnapshotStore {
        var items: [String: ManualInventorySnapshot]
        var order: [String]

        init(items: [String: ManualInventorySnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualInventorySnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualInventorySnapshot) {
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

        func list() -> [ManualInventorySnapshot] {
            var out: [ManualInventorySnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualInventorySnapshotStore() -> any ManualInventorySnapshotStore {
        return MemoryManualInventorySnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualInventorySnapshotStore: ManualInventorySnapshotStore {
        var inner: MemoryManualInventorySnapshotStore
        var cache: TTLCache<ManualInventorySnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualInventorySnapshotStore, cache: TTLCache<ManualInventorySnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualInventorySnapshot? {
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

        func save(_ item: ManualInventorySnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualInventorySnapshot] {
            return inner.list()
        }
    }

    static func newCachedManualInventorySnapshotStore(_ inner: MemoryManualInventorySnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualInventorySnapshotStore {
        return CachedManualInventorySnapshotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual inventory snapshots. Empty fields match all.
    final class ManualInventorySnapshotQuery {
        var channel: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualInventorySnapshot) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [ManualInventorySnapshot]) -> [ManualInventorySnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualInventorySnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualInventorySnapshots(_ store: any ManualInventorySnapshotStore, query: ManualInventorySnapshotQuery) -> [ManualInventorySnapshot] {
        return query.apply(store.list())
    }
}
