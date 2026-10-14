import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps legacy care gap snapshots by code.
    protocol LegacyCareGapSnapshotStore {
        func find(_ code: String) -> LegacyCareGapSnapshot?
        func save(_ item: LegacyCareGapSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyCareGapSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyCareGapSnapshotStore: LegacyCareGapSnapshotStore {
        var items: [String: LegacyCareGapSnapshot]
        var order: [String]

        init(items: [String: LegacyCareGapSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyCareGapSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyCareGapSnapshot) {
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

        func list() -> [LegacyCareGapSnapshot] {
            var out: [LegacyCareGapSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyCareGapSnapshotStore() -> any LegacyCareGapSnapshotStore {
        return MemoryLegacyCareGapSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyCareGapSnapshotStore: LegacyCareGapSnapshotStore {
        var inner: MemoryLegacyCareGapSnapshotStore
        var cache: TTLCache<LegacyCareGapSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyCareGapSnapshotStore, cache: TTLCache<LegacyCareGapSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyCareGapSnapshot? {
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

        func save(_ item: LegacyCareGapSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyCareGapSnapshot] {
            return inner.list()
        }
    }

    static func newCachedLegacyCareGapSnapshotStore(_ inner: MemoryLegacyCareGapSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyCareGapSnapshotStore {
        return CachedLegacyCareGapSnapshotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy care gap snapshots. Empty fields match all.
    final class LegacyCareGapSnapshotQuery {
        var channel: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyCareGapSnapshot) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyCareGapSnapshot]) -> [LegacyCareGapSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyCareGapSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyCareGapSnapshots(_ store: any LegacyCareGapSnapshotStore, query: LegacyCareGapSnapshotQuery) -> [LegacyCareGapSnapshot] {
        return query.apply(store.list())
    }
}
