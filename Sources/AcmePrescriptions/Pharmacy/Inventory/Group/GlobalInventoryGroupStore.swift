import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps global inventory groups by code.
    protocol GlobalInventoryGroupStore {
        func find(_ code: String) -> GlobalInventoryGroup?
        func save(_ item: GlobalInventoryGroup)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalInventoryGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalInventoryGroupStore: GlobalInventoryGroupStore {
        var items: [String: GlobalInventoryGroup]
        var order: [String]

        init(items: [String: GlobalInventoryGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalInventoryGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalInventoryGroup) {
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

        func list() -> [GlobalInventoryGroup] {
            var out: [GlobalInventoryGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalInventoryGroupStore() -> any GlobalInventoryGroupStore {
        return MemoryGlobalInventoryGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalInventoryGroupStore: GlobalInventoryGroupStore {
        var inner: MemoryGlobalInventoryGroupStore
        var cache: TTLCache<GlobalInventoryGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalInventoryGroupStore, cache: TTLCache<GlobalInventoryGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalInventoryGroup? {
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

        func save(_ item: GlobalInventoryGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalInventoryGroup] {
            return inner.list()
        }
    }

    static func newCachedGlobalInventoryGroupStore(_ inner: MemoryGlobalInventoryGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalInventoryGroupStore {
        return CachedGlobalInventoryGroupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global inventory groups. Empty fields match all.
    final class GlobalInventoryGroupQuery {
        var title: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalInventoryGroup) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalInventoryGroup]) -> [GlobalInventoryGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalInventoryGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalInventoryGroups(_ store: any GlobalInventoryGroupStore, query: GlobalInventoryGroupQuery) -> [GlobalInventoryGroup] {
        return query.apply(store.list())
    }
}
