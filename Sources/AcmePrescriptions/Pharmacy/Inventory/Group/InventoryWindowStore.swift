import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory windows by code.
    protocol InventoryWindowStore {
        func find(_ code: String) -> InventoryWindow?
        func save(_ item: InventoryWindow)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryWindowStore: InventoryWindowStore {
        var items: [String: InventoryWindow]
        var order: [String]

        init(items: [String: InventoryWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryWindow) {
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

        func list() -> [InventoryWindow] {
            var out: [InventoryWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryWindowStore() -> any InventoryWindowStore {
        return MemoryInventoryWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryWindowStore: InventoryWindowStore {
        var inner: MemoryInventoryWindowStore
        var cache: TTLCache<InventoryWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryWindowStore, cache: TTLCache<InventoryWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryWindow? {
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

        func save(_ item: InventoryWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryWindow] {
            return inner.list()
        }
    }

    static func newCachedInventoryWindowStore(_ inner: MemoryInventoryWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryWindowStore {
        return CachedInventoryWindowStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory windows. Empty fields match all.
    final class InventoryWindowQuery {
        var source: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minWeight: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventoryWindow) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InventoryWindow]) -> [InventoryWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryWindows(_ store: any InventoryWindowStore, query: InventoryWindowQuery) -> [InventoryWindow] {
        return query.apply(store.list())
    }
}
