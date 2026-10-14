import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps tiered slot snapshots by code.
    protocol TieredSlotSnapshotStore {
        func find(_ code: String) -> TieredSlotSnapshot?
        func save(_ item: TieredSlotSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [TieredSlotSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredSlotSnapshotStore: TieredSlotSnapshotStore {
        var items: [String: TieredSlotSnapshot]
        var order: [String]

        init(items: [String: TieredSlotSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredSlotSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredSlotSnapshot) {
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

        func list() -> [TieredSlotSnapshot] {
            var out: [TieredSlotSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredSlotSnapshotStore() -> any TieredSlotSnapshotStore {
        return MemoryTieredSlotSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredSlotSnapshotStore: TieredSlotSnapshotStore {
        var inner: MemoryTieredSlotSnapshotStore
        var cache: TTLCache<TieredSlotSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredSlotSnapshotStore, cache: TTLCache<TieredSlotSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredSlotSnapshot? {
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

        func save(_ item: TieredSlotSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredSlotSnapshot] {
            return inner.list()
        }
    }

    static func newCachedTieredSlotSnapshotStore(_ inner: MemoryTieredSlotSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredSlotSnapshotStore {
        return CachedTieredSlotSnapshotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered slot snapshots. Empty fields match all.
    final class TieredSlotSnapshotQuery {
        var country: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredSlotSnapshot) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredSlotSnapshot]) -> [TieredSlotSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredSlotSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredSlotSnapshots(_ store: any TieredSlotSnapshotStore, query: TieredSlotSnapshotQuery) -> [TieredSlotSnapshot] {
        return query.apply(store.list())
    }
}
