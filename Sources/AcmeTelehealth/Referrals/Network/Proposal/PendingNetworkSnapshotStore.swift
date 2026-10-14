import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps pending network snapshots by code.
    protocol PendingNetworkSnapshotStore {
        func find(_ code: String) -> PendingNetworkSnapshot?
        func save(_ item: PendingNetworkSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [PendingNetworkSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingNetworkSnapshotStore: PendingNetworkSnapshotStore {
        var items: [String: PendingNetworkSnapshot]
        var order: [String]

        init(items: [String: PendingNetworkSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingNetworkSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingNetworkSnapshot) {
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

        func list() -> [PendingNetworkSnapshot] {
            var out: [PendingNetworkSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingNetworkSnapshotStore() -> any PendingNetworkSnapshotStore {
        return MemoryPendingNetworkSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingNetworkSnapshotStore: PendingNetworkSnapshotStore {
        var inner: MemoryPendingNetworkSnapshotStore
        var cache: TTLCache<PendingNetworkSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingNetworkSnapshotStore, cache: TTLCache<PendingNetworkSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingNetworkSnapshot? {
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

        func save(_ item: PendingNetworkSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingNetworkSnapshot] {
            return inner.list()
        }
    }

    static func newCachedPendingNetworkSnapshotStore(_ inner: MemoryPendingNetworkSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingNetworkSnapshotStore {
        return CachedPendingNetworkSnapshotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending network snapshots. Empty fields match all.
    final class PendingNetworkSnapshotQuery {
        var channel: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingNetworkSnapshot) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingNetworkSnapshot]) -> [PendingNetworkSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingNetworkSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingNetworkSnapshots(_ store: any PendingNetworkSnapshotStore, query: PendingNetworkSnapshotQuery) -> [PendingNetworkSnapshot] {
        return query.apply(store.list())
    }
}
