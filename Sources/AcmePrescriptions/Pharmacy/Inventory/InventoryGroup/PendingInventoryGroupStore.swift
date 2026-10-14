import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps pending inventory groups by code.
    protocol PendingInventoryGroupStore {
        func find(_ code: String) -> PendingInventoryGroup?
        func save(_ item: PendingInventoryGroup)
        func remove(_ code: String) -> Bool
        func list() -> [PendingInventoryGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingInventoryGroupStore: PendingInventoryGroupStore {
        var items: [String: PendingInventoryGroup]
        var order: [String]

        init(items: [String: PendingInventoryGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingInventoryGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingInventoryGroup) {
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

        func list() -> [PendingInventoryGroup] {
            var out: [PendingInventoryGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingInventoryGroupStore() -> any PendingInventoryGroupStore {
        return MemoryPendingInventoryGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingInventoryGroupStore: PendingInventoryGroupStore {
        var inner: MemoryPendingInventoryGroupStore
        var cache: TTLCache<PendingInventoryGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingInventoryGroupStore, cache: TTLCache<PendingInventoryGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingInventoryGroup? {
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

        func save(_ item: PendingInventoryGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingInventoryGroup] {
            return inner.list()
        }
    }

    static func newCachedPendingInventoryGroupStore(_ inner: MemoryPendingInventoryGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingInventoryGroupStore {
        return CachedPendingInventoryGroupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending inventory groups. Empty fields match all.
    final class PendingInventoryGroupQuery {
        var title: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minLimit: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingInventoryGroup) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingInventoryGroup]) -> [PendingInventoryGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingInventoryGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingInventoryGroups(_ store: any PendingInventoryGroupStore, query: PendingInventoryGroupQuery) -> [PendingInventoryGroup] {
        return query.apply(store.list())
    }
}
