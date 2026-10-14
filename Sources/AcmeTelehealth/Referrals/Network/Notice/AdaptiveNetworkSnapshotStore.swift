import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps adaptive network snapshots by code.
    protocol AdaptiveNetworkSnapshotStore {
        func find(_ code: String) -> AdaptiveNetworkSnapshot?
        func save(_ item: AdaptiveNetworkSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveNetworkSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveNetworkSnapshotStore: AdaptiveNetworkSnapshotStore {
        var items: [String: AdaptiveNetworkSnapshot]
        var order: [String]

        init(items: [String: AdaptiveNetworkSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveNetworkSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveNetworkSnapshot) {
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

        func list() -> [AdaptiveNetworkSnapshot] {
            var out: [AdaptiveNetworkSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveNetworkSnapshotStore() -> any AdaptiveNetworkSnapshotStore {
        return MemoryAdaptiveNetworkSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveNetworkSnapshotStore: AdaptiveNetworkSnapshotStore {
        var inner: MemoryAdaptiveNetworkSnapshotStore
        var cache: TTLCache<AdaptiveNetworkSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveNetworkSnapshotStore, cache: TTLCache<AdaptiveNetworkSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveNetworkSnapshot? {
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

        func save(_ item: AdaptiveNetworkSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveNetworkSnapshot] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveNetworkSnapshotStore(_ inner: MemoryAdaptiveNetworkSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveNetworkSnapshotStore {
        return CachedAdaptiveNetworkSnapshotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive network snapshots. Empty fields match all.
    final class AdaptiveNetworkSnapshotQuery {
        var label: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveNetworkSnapshot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [AdaptiveNetworkSnapshot]) -> [AdaptiveNetworkSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveNetworkSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveNetworkSnapshots(_ store: any AdaptiveNetworkSnapshotStore, query: AdaptiveNetworkSnapshotQuery) -> [AdaptiveNetworkSnapshot] {
        return query.apply(store.list())
    }
}
