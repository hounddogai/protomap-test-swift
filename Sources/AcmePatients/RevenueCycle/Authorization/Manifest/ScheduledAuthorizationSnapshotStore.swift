import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps scheduled authorization snapshots by code.
    protocol ScheduledAuthorizationSnapshotStore {
        func find(_ code: String) -> ScheduledAuthorizationSnapshot?
        func save(_ item: ScheduledAuthorizationSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledAuthorizationSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledAuthorizationSnapshotStore: ScheduledAuthorizationSnapshotStore {
        var items: [String: ScheduledAuthorizationSnapshot]
        var order: [String]

        init(items: [String: ScheduledAuthorizationSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledAuthorizationSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledAuthorizationSnapshot) {
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

        func list() -> [ScheduledAuthorizationSnapshot] {
            var out: [ScheduledAuthorizationSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledAuthorizationSnapshotStore() -> any ScheduledAuthorizationSnapshotStore {
        return MemoryScheduledAuthorizationSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledAuthorizationSnapshotStore: ScheduledAuthorizationSnapshotStore {
        var inner: MemoryScheduledAuthorizationSnapshotStore
        var cache: TTLCache<ScheduledAuthorizationSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledAuthorizationSnapshotStore, cache: TTLCache<ScheduledAuthorizationSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledAuthorizationSnapshot? {
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

        func save(_ item: ScheduledAuthorizationSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledAuthorizationSnapshot] {
            return inner.list()
        }
    }

    static func newCachedScheduledAuthorizationSnapshotStore(_ inner: MemoryScheduledAuthorizationSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledAuthorizationSnapshotStore {
        return CachedScheduledAuthorizationSnapshotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled authorization snapshots. Empty fields match all.
    final class ScheduledAuthorizationSnapshotQuery {
        var title: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minAmount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledAuthorizationSnapshot) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledAuthorizationSnapshot]) -> [ScheduledAuthorizationSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledAuthorizationSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledAuthorizationSnapshots(_ store: any ScheduledAuthorizationSnapshotStore, query: ScheduledAuthorizationSnapshotQuery) -> [ScheduledAuthorizationSnapshot] {
        return query.apply(store.list())
    }
}
