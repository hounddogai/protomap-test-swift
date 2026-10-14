import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps legacy overtime snapshots by code.
    protocol LegacyOvertimeSnapshotStore {
        func find(_ code: String) -> LegacyOvertimeSnapshot?
        func save(_ item: LegacyOvertimeSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyOvertimeSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyOvertimeSnapshotStore: LegacyOvertimeSnapshotStore {
        var items: [String: LegacyOvertimeSnapshot]
        var order: [String]

        init(items: [String: LegacyOvertimeSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyOvertimeSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyOvertimeSnapshot) {
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

        func list() -> [LegacyOvertimeSnapshot] {
            var out: [LegacyOvertimeSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyOvertimeSnapshotStore() -> any LegacyOvertimeSnapshotStore {
        return MemoryLegacyOvertimeSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyOvertimeSnapshotStore: LegacyOvertimeSnapshotStore {
        var inner: MemoryLegacyOvertimeSnapshotStore
        var cache: TTLCache<LegacyOvertimeSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyOvertimeSnapshotStore, cache: TTLCache<LegacyOvertimeSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyOvertimeSnapshot? {
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

        func save(_ item: LegacyOvertimeSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyOvertimeSnapshot] {
            return inner.list()
        }
    }

    static func newCachedLegacyOvertimeSnapshotStore(_ inner: MemoryLegacyOvertimeSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyOvertimeSnapshotStore {
        return CachedLegacyOvertimeSnapshotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy overtime snapshots. Empty fields match all.
    final class LegacyOvertimeSnapshotQuery {
        var category: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyOvertimeSnapshot) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyOvertimeSnapshot]) -> [LegacyOvertimeSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyOvertimeSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyOvertimeSnapshots(_ store: any LegacyOvertimeSnapshotStore, query: LegacyOvertimeSnapshotQuery) -> [LegacyOvertimeSnapshot] {
        return query.apply(store.list())
    }
}
