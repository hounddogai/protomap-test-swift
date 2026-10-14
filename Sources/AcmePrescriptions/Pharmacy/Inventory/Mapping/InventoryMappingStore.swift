import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory mappings by code.
    protocol InventoryMappingStore {
        func find(_ code: String) -> InventoryMapping?
        func save(_ item: InventoryMapping)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryMappingStore: InventoryMappingStore {
        var items: [String: InventoryMapping]
        var order: [String]

        init(items: [String: InventoryMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryMapping) {
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

        func list() -> [InventoryMapping] {
            var out: [InventoryMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryMappingStore() -> any InventoryMappingStore {
        return MemoryInventoryMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryMappingStore: InventoryMappingStore {
        var inner: MemoryInventoryMappingStore
        var cache: TTLCache<InventoryMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryMappingStore, cache: TTLCache<InventoryMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryMapping? {
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

        func save(_ item: InventoryMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryMapping] {
            return inner.list()
        }
    }

    static func newCachedInventoryMappingStore(_ inner: MemoryInventoryMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryMappingStore {
        return CachedInventoryMappingStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory mappings. Empty fields match all.
    final class InventoryMappingQuery {
        var title: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventoryMapping) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InventoryMapping]) -> [InventoryMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryMappings(_ store: any InventoryMappingStore, query: InventoryMappingQuery) -> [InventoryMapping] {
        return query.apply(store.list())
    }
}
