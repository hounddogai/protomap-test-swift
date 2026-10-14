import AcmePlatform
import Foundation

extension Consent {
    /// Keeps scheduled revocation snapshots by code.
    protocol ScheduledRevocationSnapshotStore {
        func find(_ code: String) -> ScheduledRevocationSnapshot?
        func save(_ item: ScheduledRevocationSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledRevocationSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledRevocationSnapshotStore: ScheduledRevocationSnapshotStore {
        var items: [String: ScheduledRevocationSnapshot]
        var order: [String]

        init(items: [String: ScheduledRevocationSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledRevocationSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledRevocationSnapshot) {
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

        func list() -> [ScheduledRevocationSnapshot] {
            var out: [ScheduledRevocationSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledRevocationSnapshotStore() -> any ScheduledRevocationSnapshotStore {
        return MemoryScheduledRevocationSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledRevocationSnapshotStore: ScheduledRevocationSnapshotStore {
        var inner: MemoryScheduledRevocationSnapshotStore
        var cache: TTLCache<ScheduledRevocationSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledRevocationSnapshotStore, cache: TTLCache<ScheduledRevocationSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledRevocationSnapshot? {
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

        func save(_ item: ScheduledRevocationSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledRevocationSnapshot] {
            return inner.list()
        }
    }

    static func newCachedScheduledRevocationSnapshotStore(_ inner: MemoryScheduledRevocationSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledRevocationSnapshotStore {
        return CachedScheduledRevocationSnapshotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled revocation snapshots. Empty fields match all.
    final class ScheduledRevocationSnapshotQuery {
        var name: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMargin: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledRevocationSnapshot) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledRevocationSnapshot]) -> [ScheduledRevocationSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledRevocationSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledRevocationSnapshots(_ store: any ScheduledRevocationSnapshotStore, query: ScheduledRevocationSnapshotQuery) -> [ScheduledRevocationSnapshot] {
        return query.apply(store.list())
    }
}
