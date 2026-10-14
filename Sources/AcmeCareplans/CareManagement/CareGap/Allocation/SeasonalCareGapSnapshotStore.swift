import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps seasonal care gap snapshots by code.
    protocol SeasonalCareGapSnapshotStore {
        func find(_ code: String) -> SeasonalCareGapSnapshot?
        func save(_ item: SeasonalCareGapSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalCareGapSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalCareGapSnapshotStore: SeasonalCareGapSnapshotStore {
        var items: [String: SeasonalCareGapSnapshot]
        var order: [String]

        init(items: [String: SeasonalCareGapSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalCareGapSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalCareGapSnapshot) {
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

        func list() -> [SeasonalCareGapSnapshot] {
            var out: [SeasonalCareGapSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalCareGapSnapshotStore() -> any SeasonalCareGapSnapshotStore {
        return MemorySeasonalCareGapSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalCareGapSnapshotStore: SeasonalCareGapSnapshotStore {
        var inner: MemorySeasonalCareGapSnapshotStore
        var cache: TTLCache<SeasonalCareGapSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalCareGapSnapshotStore, cache: TTLCache<SeasonalCareGapSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalCareGapSnapshot? {
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

        func save(_ item: SeasonalCareGapSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalCareGapSnapshot] {
            return inner.list()
        }
    }

    static func newCachedSeasonalCareGapSnapshotStore(_ inner: MemorySeasonalCareGapSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalCareGapSnapshotStore {
        return CachedSeasonalCareGapSnapshotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal care gap snapshots. Empty fields match all.
    final class SeasonalCareGapSnapshotQuery {
        var channel: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalCareGapSnapshot) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalCareGapSnapshot]) -> [SeasonalCareGapSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalCareGapSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalCareGapSnapshots(_ store: any SeasonalCareGapSnapshotStore, query: SeasonalCareGapSnapshotQuery) -> [SeasonalCareGapSnapshot] {
        return query.apply(store.list())
    }
}
