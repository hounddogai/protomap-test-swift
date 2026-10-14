import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist groups by code.
    protocol WorklistGroupStore {
        func find(_ code: String) -> WorklistGroup?
        func save(_ item: WorklistGroup)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistGroupStore: WorklistGroupStore {
        var items: [String: WorklistGroup]
        var order: [String]

        init(items: [String: WorklistGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistGroup) {
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

        func list() -> [WorklistGroup] {
            var out: [WorklistGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistGroupStore() -> any WorklistGroupStore {
        return MemoryWorklistGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistGroupStore: WorklistGroupStore {
        var inner: MemoryWorklistGroupStore
        var cache: TTLCache<WorklistGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistGroupStore, cache: TTLCache<WorklistGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistGroup? {
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

        func save(_ item: WorklistGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistGroup] {
            return inner.list()
        }
    }

    static func newCachedWorklistGroupStore(_ inner: MemoryWorklistGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistGroupStore {
        return CachedWorklistGroupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist groups. Empty fields match all.
    final class WorklistGroupQuery {
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

        func matches(_ item: WorklistGroup) -> Bool {
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

        func apply(_ items: [WorklistGroup]) -> [WorklistGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistGroups(_ store: any WorklistGroupStore, query: WorklistGroupQuery) -> [WorklistGroup] {
        return query.apply(store.list())
    }
}
