import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up snapshots by code.
    protocol FollowUpSnapshotStore {
        func find(_ code: String) -> FollowUpSnapshot?
        func save(_ item: FollowUpSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpSnapshotStore: FollowUpSnapshotStore {
        var items: [String: FollowUpSnapshot]
        var order: [String]

        init(items: [String: FollowUpSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpSnapshot) {
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

        func list() -> [FollowUpSnapshot] {
            var out: [FollowUpSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpSnapshotStore() -> any FollowUpSnapshotStore {
        return MemoryFollowUpSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpSnapshotStore: FollowUpSnapshotStore {
        var inner: MemoryFollowUpSnapshotStore
        var cache: TTLCache<FollowUpSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpSnapshotStore, cache: TTLCache<FollowUpSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpSnapshot? {
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

        func save(_ item: FollowUpSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpSnapshot] {
            return inner.list()
        }
    }

    static func newCachedFollowUpSnapshotStore(_ inner: MemoryFollowUpSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpSnapshotStore {
        return CachedFollowUpSnapshotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up snapshots. Empty fields match all.
    final class FollowUpSnapshotQuery {
        var unit: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpSnapshot) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpSnapshot]) -> [FollowUpSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpSnapshots(_ store: any FollowUpSnapshotStore, query: FollowUpSnapshotQuery) -> [FollowUpSnapshot] {
        return query.apply(store.list())
    }
}
