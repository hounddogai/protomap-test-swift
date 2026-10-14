import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task targets by code.
    protocol TaskTargetStore {
        func find(_ code: String) -> TaskTarget?
        func save(_ item: TaskTarget)
        func remove(_ code: String) -> Bool
        func list() -> [TaskTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskTargetStore: TaskTargetStore {
        var items: [String: TaskTarget]
        var order: [String]

        init(items: [String: TaskTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskTarget) {
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

        func list() -> [TaskTarget] {
            var out: [TaskTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskTargetStore() -> any TaskTargetStore {
        return MemoryTaskTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskTargetStore: TaskTargetStore {
        var inner: MemoryTaskTargetStore
        var cache: TTLCache<TaskTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskTargetStore, cache: TTLCache<TaskTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskTarget? {
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

        func save(_ item: TaskTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskTarget] {
            return inner.list()
        }
    }

    static func newCachedTaskTargetStore(_ inner: MemoryTaskTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskTargetStore {
        return CachedTaskTargetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task targets. Empty fields match all.
    final class TaskTargetQuery {
        var facility: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskTarget) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TaskTarget]) -> [TaskTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskTargets(_ store: any TaskTargetStore, query: TaskTargetQuery) -> [TaskTarget] {
        return query.apply(store.list())
    }
}
