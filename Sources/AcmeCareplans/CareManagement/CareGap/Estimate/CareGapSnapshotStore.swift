import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap snapshots by code.
    protocol CareGapSnapshotStore {
        func find(_ code: String) -> CareGapSnapshot?
        func save(_ item: CareGapSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapSnapshotStore: CareGapSnapshotStore {
        var items: [String: CareGapSnapshot]
        var order: [String]

        init(items: [String: CareGapSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapSnapshot) {
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

        func list() -> [CareGapSnapshot] {
            var out: [CareGapSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapSnapshotStore() -> any CareGapSnapshotStore {
        return MemoryCareGapSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapSnapshotStore: CareGapSnapshotStore {
        var inner: MemoryCareGapSnapshotStore
        var cache: TTLCache<CareGapSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapSnapshotStore, cache: TTLCache<CareGapSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapSnapshot? {
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

        func save(_ item: CareGapSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapSnapshot] {
            return inner.list()
        }
    }

    static func newCachedCareGapSnapshotStore(_ inner: MemoryCareGapSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapSnapshotStore {
        return CachedCareGapSnapshotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap snapshots. Empty fields match all.
    final class CareGapSnapshotQuery {
        var segment: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapSnapshot) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [CareGapSnapshot]) -> [CareGapSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapSnapshots(_ store: any CareGapSnapshotStore, query: CareGapSnapshotQuery) -> [CareGapSnapshot] {
        return query.apply(store.list())
    }
}
