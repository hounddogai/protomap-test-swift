import AcmePlatform
import Foundation

extension Consent {
    /// Keeps strict language snapshots by code.
    protocol StrictLanguageSnapshotStore {
        func find(_ code: String) -> StrictLanguageSnapshot?
        func save(_ item: StrictLanguageSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [StrictLanguageSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictLanguageSnapshotStore: StrictLanguageSnapshotStore {
        var items: [String: StrictLanguageSnapshot]
        var order: [String]

        init(items: [String: StrictLanguageSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictLanguageSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictLanguageSnapshot) {
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

        func list() -> [StrictLanguageSnapshot] {
            var out: [StrictLanguageSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictLanguageSnapshotStore() -> any StrictLanguageSnapshotStore {
        return MemoryStrictLanguageSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictLanguageSnapshotStore: StrictLanguageSnapshotStore {
        var inner: MemoryStrictLanguageSnapshotStore
        var cache: TTLCache<StrictLanguageSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictLanguageSnapshotStore, cache: TTLCache<StrictLanguageSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictLanguageSnapshot? {
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

        func save(_ item: StrictLanguageSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictLanguageSnapshot] {
            return inner.list()
        }
    }

    static func newCachedStrictLanguageSnapshotStore(_ inner: MemoryStrictLanguageSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictLanguageSnapshotStore {
        return CachedStrictLanguageSnapshotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict language snapshots. Empty fields match all.
    final class StrictLanguageSnapshotQuery {
        var segment: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictLanguageSnapshot) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [StrictLanguageSnapshot]) -> [StrictLanguageSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictLanguageSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictLanguageSnapshots(_ store: any StrictLanguageSnapshotStore, query: StrictLanguageSnapshotQuery) -> [StrictLanguageSnapshot] {
        return query.apply(store.list())
    }
}
