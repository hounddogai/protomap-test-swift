import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps scheduled claim snapshots by code.
    protocol ScheduledClaimSnapshotStore {
        func find(_ code: String) -> ScheduledClaimSnapshot?
        func save(_ item: ScheduledClaimSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledClaimSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledClaimSnapshotStore: ScheduledClaimSnapshotStore {
        var items: [String: ScheduledClaimSnapshot]
        var order: [String]

        init(items: [String: ScheduledClaimSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledClaimSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledClaimSnapshot) {
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

        func list() -> [ScheduledClaimSnapshot] {
            var out: [ScheduledClaimSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledClaimSnapshotStore() -> any ScheduledClaimSnapshotStore {
        return MemoryScheduledClaimSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledClaimSnapshotStore: ScheduledClaimSnapshotStore {
        var inner: MemoryScheduledClaimSnapshotStore
        var cache: TTLCache<ScheduledClaimSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledClaimSnapshotStore, cache: TTLCache<ScheduledClaimSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledClaimSnapshot? {
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

        func save(_ item: ScheduledClaimSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledClaimSnapshot] {
            return inner.list()
        }
    }

    static func newCachedScheduledClaimSnapshotStore(_ inner: MemoryScheduledClaimSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledClaimSnapshotStore {
        return CachedScheduledClaimSnapshotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled claim snapshots. Empty fields match all.
    final class ScheduledClaimSnapshotQuery {
        var segment: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minLimit: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledClaimSnapshot) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledClaimSnapshot]) -> [ScheduledClaimSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledClaimSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledClaimSnapshots(_ store: any ScheduledClaimSnapshotStore, query: ScheduledClaimSnapshotQuery) -> [ScheduledClaimSnapshot] {
        return query.apply(store.list())
    }
}
