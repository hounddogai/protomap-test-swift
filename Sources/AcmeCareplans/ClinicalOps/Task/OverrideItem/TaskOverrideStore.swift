import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task overrides by code.
    protocol TaskOverrideStore {
        func find(_ code: String) -> TaskOverride?
        func save(_ item: TaskOverride)
        func remove(_ code: String) -> Bool
        func list() -> [TaskOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskOverrideStore: TaskOverrideStore {
        var items: [String: TaskOverride]
        var order: [String]

        init(items: [String: TaskOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskOverride) {
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

        func list() -> [TaskOverride] {
            var out: [TaskOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskOverrideStore() -> any TaskOverrideStore {
        return MemoryTaskOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskOverrideStore: TaskOverrideStore {
        var inner: MemoryTaskOverrideStore
        var cache: TTLCache<TaskOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskOverrideStore, cache: TTLCache<TaskOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskOverride? {
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

        func save(_ item: TaskOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskOverride] {
            return inner.list()
        }
    }

    static func newCachedTaskOverrideStore(_ inner: MemoryTaskOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskOverrideStore {
        return CachedTaskOverrideStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task overrides. Empty fields match all.
    final class TaskOverrideQuery {
        var locale: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskOverride) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TaskOverride]) -> [TaskOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskOverrides(_ store: any TaskOverrideStore, query: TaskOverrideQuery) -> [TaskOverride] {
        return query.apply(store.list())
    }
}
