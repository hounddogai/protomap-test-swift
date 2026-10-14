import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task mappings by code.
    protocol TaskMappingStore {
        func find(_ code: String) -> TaskMapping?
        func save(_ item: TaskMapping)
        func remove(_ code: String) -> Bool
        func list() -> [TaskMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskMappingStore: TaskMappingStore {
        var items: [String: TaskMapping]
        var order: [String]

        init(items: [String: TaskMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskMapping) {
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

        func list() -> [TaskMapping] {
            var out: [TaskMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskMappingStore() -> any TaskMappingStore {
        return MemoryTaskMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskMappingStore: TaskMappingStore {
        var inner: MemoryTaskMappingStore
        var cache: TTLCache<TaskMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskMappingStore, cache: TTLCache<TaskMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskMapping? {
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

        func save(_ item: TaskMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskMapping] {
            return inner.list()
        }
    }

    static func newCachedTaskMappingStore(_ inner: MemoryTaskMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskMappingStore {
        return CachedTaskMappingStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task mappings. Empty fields match all.
    final class TaskMappingQuery {
        var locale: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minPriority: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskMapping) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [TaskMapping]) -> [TaskMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskMappings(_ store: any TaskMappingStore, query: TaskMappingQuery) -> [TaskMapping] {
        return query.apply(store.list())
    }
}
