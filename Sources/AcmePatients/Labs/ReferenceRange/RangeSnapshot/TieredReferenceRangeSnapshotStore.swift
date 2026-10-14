import AcmePlatform
import Foundation

extension Labs {
    /// Keeps tiered reference range snapshots by code.
    protocol TieredReferenceRangeSnapshotStore {
        func find(_ code: String) -> TieredReferenceRangeSnapshot?
        func save(_ item: TieredReferenceRangeSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [TieredReferenceRangeSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredReferenceRangeSnapshotStore: TieredReferenceRangeSnapshotStore {
        var items: [String: TieredReferenceRangeSnapshot]
        var order: [String]

        init(items: [String: TieredReferenceRangeSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredReferenceRangeSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredReferenceRangeSnapshot) {
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

        func list() -> [TieredReferenceRangeSnapshot] {
            var out: [TieredReferenceRangeSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredReferenceRangeSnapshotStore() -> any TieredReferenceRangeSnapshotStore {
        return MemoryTieredReferenceRangeSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredReferenceRangeSnapshotStore: TieredReferenceRangeSnapshotStore {
        var inner: MemoryTieredReferenceRangeSnapshotStore
        var cache: TTLCache<TieredReferenceRangeSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredReferenceRangeSnapshotStore, cache: TTLCache<TieredReferenceRangeSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredReferenceRangeSnapshot? {
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

        func save(_ item: TieredReferenceRangeSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredReferenceRangeSnapshot] {
            return inner.list()
        }
    }

    static func newCachedTieredReferenceRangeSnapshotStore(_ inner: MemoryTieredReferenceRangeSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredReferenceRangeSnapshotStore {
        return CachedTieredReferenceRangeSnapshotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered reference range snapshots. Empty fields match all.
    final class TieredReferenceRangeSnapshotQuery {
        var label: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minAmount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredReferenceRangeSnapshot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredReferenceRangeSnapshot]) -> [TieredReferenceRangeSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredReferenceRangeSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredReferenceRangeSnapshots(_ store: any TieredReferenceRangeSnapshotStore, query: TieredReferenceRangeSnapshotQuery) -> [TieredReferenceRangeSnapshot] {
        return query.apply(store.list())
    }
}
