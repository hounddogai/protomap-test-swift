import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps fallback census snapshots by code.
    protocol FallbackCensusSnapshotStore {
        func find(_ code: String) -> FallbackCensusSnapshot?
        func save(_ item: FallbackCensusSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackCensusSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackCensusSnapshotStore: FallbackCensusSnapshotStore {
        var items: [String: FallbackCensusSnapshot]
        var order: [String]

        init(items: [String: FallbackCensusSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackCensusSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackCensusSnapshot) {
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

        func list() -> [FallbackCensusSnapshot] {
            var out: [FallbackCensusSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackCensusSnapshotStore() -> any FallbackCensusSnapshotStore {
        return MemoryFallbackCensusSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackCensusSnapshotStore: FallbackCensusSnapshotStore {
        var inner: MemoryFallbackCensusSnapshotStore
        var cache: TTLCache<FallbackCensusSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackCensusSnapshotStore, cache: TTLCache<FallbackCensusSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackCensusSnapshot? {
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

        func save(_ item: FallbackCensusSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackCensusSnapshot] {
            return inner.list()
        }
    }

    static func newCachedFallbackCensusSnapshotStore(_ inner: MemoryFallbackCensusSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackCensusSnapshotStore {
        return CachedFallbackCensusSnapshotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback census snapshots. Empty fields match all.
    final class FallbackCensusSnapshotQuery {
        var name: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackCensusSnapshot) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [FallbackCensusSnapshot]) -> [FallbackCensusSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackCensusSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackCensusSnapshots(_ store: any FallbackCensusSnapshotStore, query: FallbackCensusSnapshotQuery) -> [FallbackCensusSnapshot] {
        return query.apply(store.list())
    }
}
