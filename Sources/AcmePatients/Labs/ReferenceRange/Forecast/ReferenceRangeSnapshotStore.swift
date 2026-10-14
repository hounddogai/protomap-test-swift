import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range snapshots by code.
    protocol ReferenceRangeSnapshotStore {
        func find(_ code: String) -> ReferenceRangeSnapshot?
        func save(_ item: ReferenceRangeSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeSnapshotStore: ReferenceRangeSnapshotStore {
        var items: [String: ReferenceRangeSnapshot]
        var order: [String]

        init(items: [String: ReferenceRangeSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeSnapshot) {
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

        func list() -> [ReferenceRangeSnapshot] {
            var out: [ReferenceRangeSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeSnapshotStore() -> any ReferenceRangeSnapshotStore {
        return MemoryReferenceRangeSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeSnapshotStore: ReferenceRangeSnapshotStore {
        var inner: MemoryReferenceRangeSnapshotStore
        var cache: TTLCache<ReferenceRangeSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeSnapshotStore, cache: TTLCache<ReferenceRangeSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeSnapshot? {
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

        func save(_ item: ReferenceRangeSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeSnapshot] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeSnapshotStore(_ inner: MemoryReferenceRangeSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeSnapshotStore {
        return CachedReferenceRangeSnapshotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range snapshots. Empty fields match all.
    final class ReferenceRangeSnapshotQuery {
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

        func matches(_ item: ReferenceRangeSnapshot) -> Bool {
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

        func apply(_ items: [ReferenceRangeSnapshot]) -> [ReferenceRangeSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeSnapshots(_ store: any ReferenceRangeSnapshotStore, query: ReferenceRangeSnapshotQuery) -> [ReferenceRangeSnapshot] {
        return query.apply(store.list())
    }
}
