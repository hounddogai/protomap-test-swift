import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task groups by code.
    protocol TaskGroupStore {
        func find(_ code: String) -> TaskGroup?
        func save(_ item: TaskGroup)
        func remove(_ code: String) -> Bool
        func list() -> [TaskGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskGroupStore: TaskGroupStore {
        var items: [String: TaskGroup]
        var order: [String]

        init(items: [String: TaskGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskGroup) {
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

        func list() -> [TaskGroup] {
            var out: [TaskGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskGroupStore() -> any TaskGroupStore {
        return MemoryTaskGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskGroupStore: TaskGroupStore {
        var inner: MemoryTaskGroupStore
        var cache: TTLCache<TaskGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskGroupStore, cache: TTLCache<TaskGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskGroup? {
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

        func save(_ item: TaskGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskGroup] {
            return inner.list()
        }
    }

    static func newCachedTaskGroupStore(_ inner: MemoryTaskGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskGroupStore {
        return CachedTaskGroupStore(inner: inner, cache: newTTLCache(64, ttl: ttl, clock: clock), hits: 0, misses: 0)
    }

    /// Selects task groups. Empty fields match all.
    final class TaskGroupQuery {
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

        func matches(_ item: TaskGroup) -> Bool {
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

        func apply(_ items: [TaskGroup]) -> [TaskGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskGroups(_ store: any TaskGroupStore, query: TaskGroupQuery) -> [TaskGroup] {
        return query.apply(store.list())
    }
}
