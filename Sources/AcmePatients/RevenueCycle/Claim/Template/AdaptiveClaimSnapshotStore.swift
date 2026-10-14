import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps adaptive claim snapshots by code.
    protocol AdaptiveClaimSnapshotStore {
        func find(_ code: String) -> AdaptiveClaimSnapshot?
        func save(_ item: AdaptiveClaimSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveClaimSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveClaimSnapshotStore: AdaptiveClaimSnapshotStore {
        var items: [String: AdaptiveClaimSnapshot]
        var order: [String]

        init(items: [String: AdaptiveClaimSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveClaimSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveClaimSnapshot) {
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

        func list() -> [AdaptiveClaimSnapshot] {
            var out: [AdaptiveClaimSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveClaimSnapshotStore() -> any AdaptiveClaimSnapshotStore {
        return MemoryAdaptiveClaimSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveClaimSnapshotStore: AdaptiveClaimSnapshotStore {
        var inner: MemoryAdaptiveClaimSnapshotStore
        var cache: TTLCache<AdaptiveClaimSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveClaimSnapshotStore, cache: TTLCache<AdaptiveClaimSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveClaimSnapshot? {
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

        func save(_ item: AdaptiveClaimSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveClaimSnapshot] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveClaimSnapshotStore(_ inner: MemoryAdaptiveClaimSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveClaimSnapshotStore {
        return CachedAdaptiveClaimSnapshotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive claim snapshots. Empty fields match all.
    final class AdaptiveClaimSnapshotQuery {
        var name: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveClaimSnapshot) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveClaimSnapshot]) -> [AdaptiveClaimSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveClaimSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveClaimSnapshots(_ store: any AdaptiveClaimSnapshotStore, query: AdaptiveClaimSnapshotQuery) -> [AdaptiveClaimSnapshot] {
        return query.apply(store.list())
    }
}
