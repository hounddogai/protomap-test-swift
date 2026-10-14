import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps primary shift snapshots by code.
    protocol PrimaryShiftSnapshotStore {
        func find(_ code: String) -> PrimaryShiftSnapshot?
        func save(_ item: PrimaryShiftSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryShiftSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryShiftSnapshotStore: PrimaryShiftSnapshotStore {
        var items: [String: PrimaryShiftSnapshot]
        var order: [String]

        init(items: [String: PrimaryShiftSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryShiftSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryShiftSnapshot) {
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

        func list() -> [PrimaryShiftSnapshot] {
            var out: [PrimaryShiftSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryShiftSnapshotStore() -> any PrimaryShiftSnapshotStore {
        return MemoryPrimaryShiftSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryShiftSnapshotStore: PrimaryShiftSnapshotStore {
        var inner: MemoryPrimaryShiftSnapshotStore
        var cache: TTLCache<PrimaryShiftSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryShiftSnapshotStore, cache: TTLCache<PrimaryShiftSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryShiftSnapshot? {
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

        func save(_ item: PrimaryShiftSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryShiftSnapshot] {
            return inner.list()
        }
    }

    static func newCachedPrimaryShiftSnapshotStore(_ inner: MemoryPrimaryShiftSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryShiftSnapshotStore {
        return CachedPrimaryShiftSnapshotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary shift snapshots. Empty fields match all.
    final class PrimaryShiftSnapshotQuery {
        var locale: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minBudget: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryShiftSnapshot) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryShiftSnapshot]) -> [PrimaryShiftSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryShiftSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryShiftSnapshots(_ store: any PrimaryShiftSnapshotStore, query: PrimaryShiftSnapshotQuery) -> [PrimaryShiftSnapshot] {
        return query.apply(store.list())
    }
}
