import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps lenient read snapshots by code.
    protocol LenientReadSnapshotStore {
        func find(_ code: String) -> LenientReadSnapshot?
        func save(_ item: LenientReadSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [LenientReadSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientReadSnapshotStore: LenientReadSnapshotStore {
        var items: [String: LenientReadSnapshot]
        var order: [String]

        init(items: [String: LenientReadSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientReadSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientReadSnapshot) {
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

        func list() -> [LenientReadSnapshot] {
            var out: [LenientReadSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientReadSnapshotStore() -> any LenientReadSnapshotStore {
        return MemoryLenientReadSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientReadSnapshotStore: LenientReadSnapshotStore {
        var inner: MemoryLenientReadSnapshotStore
        var cache: TTLCache<LenientReadSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientReadSnapshotStore, cache: TTLCache<LenientReadSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientReadSnapshot? {
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

        func save(_ item: LenientReadSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientReadSnapshot] {
            return inner.list()
        }
    }

    static func newCachedLenientReadSnapshotStore(_ inner: MemoryLenientReadSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientReadSnapshotStore {
        return CachedLenientReadSnapshotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient read snapshots. Empty fields match all.
    final class LenientReadSnapshotQuery {
        var locale: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientReadSnapshot) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [LenientReadSnapshot]) -> [LenientReadSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientReadSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientReadSnapshots(_ store: any LenientReadSnapshotStore, query: LenientReadSnapshotQuery) -> [LenientReadSnapshot] {
        return query.apply(store.list())
    }
}
