import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task preferences by code.
    protocol TaskPreferenceStore {
        func find(_ code: String) -> TaskPreference?
        func save(_ item: TaskPreference)
        func remove(_ code: String) -> Bool
        func list() -> [TaskPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskPreferenceStore: TaskPreferenceStore {
        var items: [String: TaskPreference]
        var order: [String]

        init(items: [String: TaskPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskPreference) {
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

        func list() -> [TaskPreference] {
            var out: [TaskPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskPreferenceStore() -> any TaskPreferenceStore {
        return MemoryTaskPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskPreferenceStore: TaskPreferenceStore {
        var inner: MemoryTaskPreferenceStore
        var cache: TTLCache<TaskPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskPreferenceStore, cache: TTLCache<TaskPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskPreference? {
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

        func save(_ item: TaskPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskPreference] {
            return inner.list()
        }
    }

    static func newCachedTaskPreferenceStore(_ inner: MemoryTaskPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskPreferenceStore {
        return CachedTaskPreferenceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task preferences. Empty fields match all.
    final class TaskPreferenceQuery {
        var ward: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minRevision: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskPreference) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TaskPreference]) -> [TaskPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskPreferences(_ store: any TaskPreferenceStore, query: TaskPreferenceQuery) -> [TaskPreference] {
        return query.apply(store.list())
    }
}
