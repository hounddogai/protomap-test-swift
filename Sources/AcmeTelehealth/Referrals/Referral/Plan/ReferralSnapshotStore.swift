import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral snapshots by code.
    protocol ReferralSnapshotStore {
        func find(_ code: String) -> ReferralSnapshot?
        func save(_ item: ReferralSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralSnapshotStore: ReferralSnapshotStore {
        var items: [String: ReferralSnapshot]
        var order: [String]

        init(items: [String: ReferralSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralSnapshot) {
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

        func list() -> [ReferralSnapshot] {
            var out: [ReferralSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralSnapshotStore() -> any ReferralSnapshotStore {
        return MemoryReferralSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralSnapshotStore: ReferralSnapshotStore {
        var inner: MemoryReferralSnapshotStore
        var cache: TTLCache<ReferralSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralSnapshotStore, cache: TTLCache<ReferralSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralSnapshot? {
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

        func save(_ item: ReferralSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralSnapshot] {
            return inner.list()
        }
    }

    static func newCachedReferralSnapshotStore(_ inner: MemoryReferralSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralSnapshotStore {
        return CachedReferralSnapshotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral snapshots. Empty fields match all.
    final class ReferralSnapshotQuery {
        var region: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minSequence: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralSnapshot) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferralSnapshot]) -> [ReferralSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralSnapshots(_ store: any ReferralSnapshotStore, query: ReferralSnapshotQuery) -> [ReferralSnapshot] {
        return query.apply(store.list())
    }
}
