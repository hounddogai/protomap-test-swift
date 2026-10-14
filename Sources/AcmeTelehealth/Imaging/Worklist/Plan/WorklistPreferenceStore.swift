import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist preferences by code.
    protocol WorklistPreferenceStore {
        func find(_ code: String) -> WorklistPreference?
        func save(_ item: WorklistPreference)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistPreferenceStore: WorklistPreferenceStore {
        var items: [String: WorklistPreference]
        var order: [String]

        init(items: [String: WorklistPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistPreference) {
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

        func list() -> [WorklistPreference] {
            var out: [WorklistPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistPreferenceStore() -> any WorklistPreferenceStore {
        return MemoryWorklistPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistPreferenceStore: WorklistPreferenceStore {
        var inner: MemoryWorklistPreferenceStore
        var cache: TTLCache<WorklistPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistPreferenceStore, cache: TTLCache<WorklistPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistPreference? {
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

        func save(_ item: WorklistPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistPreference] {
            return inner.list()
        }
    }

    static func newCachedWorklistPreferenceStore(_ inner: MemoryWorklistPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistPreferenceStore {
        return CachedWorklistPreferenceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist preferences. Empty fields match all.
    final class WorklistPreferenceQuery {
        var title: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistPreference) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WorklistPreference]) -> [WorklistPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistPreferences(_ store: any WorklistPreferenceStore, query: WorklistPreferenceQuery) -> [WorklistPreference] {
        return query.apply(store.list())
    }
}
