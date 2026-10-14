import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network snapshots by code.
    protocol NetworkSnapshotStore {
        func find(_ code: String) -> NetworkSnapshot?
        func save(_ item: NetworkSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkSnapshotStore: NetworkSnapshotStore {
        var items: [String: NetworkSnapshot]
        var order: [String]

        init(items: [String: NetworkSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkSnapshot) {
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

        func list() -> [NetworkSnapshot] {
            var out: [NetworkSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkSnapshotStore() -> any NetworkSnapshotStore {
        return MemoryNetworkSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkSnapshotStore: NetworkSnapshotStore {
        var inner: MemoryNetworkSnapshotStore
        var cache: TTLCache<NetworkSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkSnapshotStore, cache: TTLCache<NetworkSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkSnapshot? {
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

        func save(_ item: NetworkSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkSnapshot] {
            return inner.list()
        }
    }

    static func newCachedNetworkSnapshotStore(_ inner: MemoryNetworkSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkSnapshotStore {
        return CachedNetworkSnapshotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network snapshots. Empty fields match all.
    final class NetworkSnapshotQuery {
        var segment: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkSnapshot) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [NetworkSnapshot]) -> [NetworkSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkSnapshots(_ store: any NetworkSnapshotStore, query: NetworkSnapshotQuery) -> [NetworkSnapshot] {
        return query.apply(store.list())
    }
}
