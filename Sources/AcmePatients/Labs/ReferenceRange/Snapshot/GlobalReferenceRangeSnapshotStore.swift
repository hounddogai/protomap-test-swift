import AcmePlatform
import Foundation

extension Labs {
    /// Keeps global reference range snapshots by code.
    protocol GlobalReferenceRangeSnapshotStore {
        func find(_ code: String) -> GlobalReferenceRangeSnapshot?
        func save(_ item: GlobalReferenceRangeSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalReferenceRangeSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalReferenceRangeSnapshotStore: GlobalReferenceRangeSnapshotStore {
        var items: [String: GlobalReferenceRangeSnapshot]
        var order: [String]

        init(items: [String: GlobalReferenceRangeSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalReferenceRangeSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalReferenceRangeSnapshot) {
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

        func list() -> [GlobalReferenceRangeSnapshot] {
            var out: [GlobalReferenceRangeSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalReferenceRangeSnapshotStore() -> any GlobalReferenceRangeSnapshotStore {
        return MemoryGlobalReferenceRangeSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalReferenceRangeSnapshotStore: GlobalReferenceRangeSnapshotStore {
        var inner: MemoryGlobalReferenceRangeSnapshotStore
        var cache: TTLCache<GlobalReferenceRangeSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalReferenceRangeSnapshotStore, cache: TTLCache<GlobalReferenceRangeSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalReferenceRangeSnapshot? {
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

        func save(_ item: GlobalReferenceRangeSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalReferenceRangeSnapshot] {
            return inner.list()
        }
    }

    static func newCachedGlobalReferenceRangeSnapshotStore(_ inner: MemoryGlobalReferenceRangeSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalReferenceRangeSnapshotStore {
        return CachedGlobalReferenceRangeSnapshotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global reference range snapshots. Empty fields match all.
    final class GlobalReferenceRangeSnapshotQuery {
        var label: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalReferenceRangeSnapshot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalReferenceRangeSnapshot]) -> [GlobalReferenceRangeSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalReferenceRangeSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalReferenceRangeSnapshots(_ store: any GlobalReferenceRangeSnapshotStore, query: GlobalReferenceRangeSnapshotQuery) -> [GlobalReferenceRangeSnapshot] {
        return query.apply(store.list())
    }
}
