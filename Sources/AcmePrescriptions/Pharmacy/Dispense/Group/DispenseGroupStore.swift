import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense groups by code.
    protocol DispenseGroupStore {
        func find(_ code: String) -> DispenseGroup?
        func save(_ item: DispenseGroup)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseGroupStore: DispenseGroupStore {
        var items: [String: DispenseGroup]
        var order: [String]

        init(items: [String: DispenseGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseGroup) {
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

        func list() -> [DispenseGroup] {
            var out: [DispenseGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseGroupStore() -> any DispenseGroupStore {
        return MemoryDispenseGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseGroupStore: DispenseGroupStore {
        var inner: MemoryDispenseGroupStore
        var cache: TTLCache<DispenseGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseGroupStore, cache: TTLCache<DispenseGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseGroup? {
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

        func save(_ item: DispenseGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseGroup] {
            return inner.list()
        }
    }

    static func newCachedDispenseGroupStore(_ inner: MemoryDispenseGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseGroupStore {
        return CachedDispenseGroupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense groups. Empty fields match all.
    final class DispenseGroupQuery {
        var name: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseGroup) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseGroup]) -> [DispenseGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseGroups(_ store: any DispenseGroupStore, query: DispenseGroupQuery) -> [DispenseGroup] {
        return query.apply(store.list())
    }
}
