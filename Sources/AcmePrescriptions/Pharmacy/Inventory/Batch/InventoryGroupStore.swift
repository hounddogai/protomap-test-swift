import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory groups by code.
    protocol InventoryGroupStore {
        func find(_ code: String) -> InventoryGroup?
        func save(_ item: InventoryGroup)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryGroupStore: InventoryGroupStore {
        var items: [String: InventoryGroup]
        var order: [String]

        init(items: [String: InventoryGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryGroup) {
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

        func list() -> [InventoryGroup] {
            var out: [InventoryGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryGroupStore() -> any InventoryGroupStore {
        return MemoryInventoryGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryGroupStore: InventoryGroupStore {
        var inner: MemoryInventoryGroupStore
        var cache: TTLCache<InventoryGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryGroupStore, cache: TTLCache<InventoryGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryGroup? {
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

        func save(_ item: InventoryGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryGroup] {
            return inner.list()
        }
    }

    static func newCachedInventoryGroupStore(_ inner: MemoryInventoryGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryGroupStore {
        return CachedInventoryGroupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory groups. Empty fields match all.
    final class InventoryGroupQuery {
        var segment: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minSequence: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventoryGroup) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InventoryGroup]) -> [InventoryGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryGroups(_ store: any InventoryGroupStore, query: InventoryGroupQuery) -> [InventoryGroup] {
        return query.apply(store.list())
    }
}
