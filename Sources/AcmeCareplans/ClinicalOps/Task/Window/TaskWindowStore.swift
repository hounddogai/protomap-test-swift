import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task windows by code.
    protocol TaskWindowStore {
        func find(_ code: String) -> TaskWindow?
        func save(_ item: TaskWindow)
        func remove(_ code: String) -> Bool
        func list() -> [TaskWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskWindowStore: TaskWindowStore {
        var items: [String: TaskWindow]
        var order: [String]

        init(items: [String: TaskWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskWindow) {
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

        func list() -> [TaskWindow] {
            var out: [TaskWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskWindowStore() -> any TaskWindowStore {
        return MemoryTaskWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskWindowStore: TaskWindowStore {
        var inner: MemoryTaskWindowStore
        var cache: TTLCache<TaskWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskWindowStore, cache: TTLCache<TaskWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskWindow? {
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

        func save(_ item: TaskWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskWindow] {
            return inner.list()
        }
    }

    static func newCachedTaskWindowStore(_ inner: MemoryTaskWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskWindowStore {
        return CachedTaskWindowStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task windows. Empty fields match all.
    final class TaskWindowQuery {
        var name: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskWindow) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TaskWindow]) -> [TaskWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskWindows(_ store: any TaskWindowStore, query: TaskWindowQuery) -> [TaskWindow] {
        return query.apply(store.list())
    }
}
