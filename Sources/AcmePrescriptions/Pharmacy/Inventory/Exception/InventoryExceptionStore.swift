import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory exceptions by code.
    protocol InventoryExceptionStore {
        func find(_ code: String) -> InventoryException?
        func save(_ item: InventoryException)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryExceptionStore: InventoryExceptionStore {
        var items: [String: InventoryException]
        var order: [String]

        init(items: [String: InventoryException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryException) {
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

        func list() -> [InventoryException] {
            var out: [InventoryException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryExceptionStore() -> any InventoryExceptionStore {
        return MemoryInventoryExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryExceptionStore: InventoryExceptionStore {
        var inner: MemoryInventoryExceptionStore
        var cache: TTLCache<InventoryException>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryExceptionStore, cache: TTLCache<InventoryException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryException? {
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

        func save(_ item: InventoryException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryException] {
            return inner.list()
        }
    }

    static func newCachedInventoryExceptionStore(_ inner: MemoryInventoryExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryExceptionStore {
        return CachedInventoryExceptionStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory exceptions. Empty fields match all.
    final class InventoryExceptionQuery {
        var unit: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minPriority: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventoryException) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InventoryException]) -> [InventoryException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryExceptions(_ store: any InventoryExceptionStore, query: InventoryExceptionQuery) -> [InventoryException] {
        return query.apply(store.list())
    }
}
