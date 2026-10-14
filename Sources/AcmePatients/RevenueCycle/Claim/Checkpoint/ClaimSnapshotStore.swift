import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim snapshots by code.
    protocol ClaimSnapshotStore {
        func find(_ code: String) -> ClaimSnapshot?
        func save(_ item: ClaimSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimSnapshotStore: ClaimSnapshotStore {
        var items: [String: ClaimSnapshot]
        var order: [String]

        init(items: [String: ClaimSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimSnapshot) {
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

        func list() -> [ClaimSnapshot] {
            var out: [ClaimSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimSnapshotStore() -> any ClaimSnapshotStore {
        return MemoryClaimSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimSnapshotStore: ClaimSnapshotStore {
        var inner: MemoryClaimSnapshotStore
        var cache: TTLCache<ClaimSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimSnapshotStore, cache: TTLCache<ClaimSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimSnapshot? {
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

        func save(_ item: ClaimSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimSnapshot] {
            return inner.list()
        }
    }

    static func newCachedClaimSnapshotStore(_ inner: MemoryClaimSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimSnapshotStore {
        return CachedClaimSnapshotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim snapshots. Empty fields match all.
    final class ClaimSnapshotQuery {
        var region: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimSnapshot) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClaimSnapshot]) -> [ClaimSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimSnapshots(_ store: any ClaimSnapshotStore, query: ClaimSnapshotQuery) -> [ClaimSnapshot] {
        return query.apply(store.list())
    }
}
