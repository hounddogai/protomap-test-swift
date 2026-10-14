import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set snapshots by code.
    protocol OrderSetSnapshotStore {
        func find(_ code: String) -> OrderSetSnapshot?
        func save(_ item: OrderSetSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetSnapshotStore: OrderSetSnapshotStore {
        var items: [String: OrderSetSnapshot]
        var order: [String]

        init(items: [String: OrderSetSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetSnapshot) {
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

        func list() -> [OrderSetSnapshot] {
            var out: [OrderSetSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetSnapshotStore() -> any OrderSetSnapshotStore {
        return MemoryOrderSetSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetSnapshotStore: OrderSetSnapshotStore {
        var inner: MemoryOrderSetSnapshotStore
        var cache: TTLCache<OrderSetSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetSnapshotStore, cache: TTLCache<OrderSetSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetSnapshot? {
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

        func save(_ item: OrderSetSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetSnapshot] {
            return inner.list()
        }
    }

    static func newCachedOrderSetSnapshotStore(_ inner: MemoryOrderSetSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetSnapshotStore {
        return CachedOrderSetSnapshotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set snapshots. Empty fields match all.
    final class OrderSetSnapshotQuery {
        var name: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetSnapshot) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [OrderSetSnapshot]) -> [OrderSetSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetSnapshots(_ store: any OrderSetSnapshotStore, query: OrderSetSnapshotQuery) -> [OrderSetSnapshot] {
        return query.apply(store.list())
    }
}
