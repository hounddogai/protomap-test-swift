import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps adaptive goal preferences by code.
    protocol AdaptiveGoalPreferenceStore {
        func find(_ code: String) -> AdaptiveGoalPreference?
        func save(_ item: AdaptiveGoalPreference)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveGoalPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveGoalPreferenceStore: AdaptiveGoalPreferenceStore {
        var items: [String: AdaptiveGoalPreference]
        var order: [String]

        init(items: [String: AdaptiveGoalPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveGoalPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveGoalPreference) {
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

        func list() -> [AdaptiveGoalPreference] {
            var out: [AdaptiveGoalPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveGoalPreferenceStore() -> any AdaptiveGoalPreferenceStore {
        return MemoryAdaptiveGoalPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveGoalPreferenceStore: AdaptiveGoalPreferenceStore {
        var inner: MemoryAdaptiveGoalPreferenceStore
        var cache: TTLCache<AdaptiveGoalPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveGoalPreferenceStore, cache: TTLCache<AdaptiveGoalPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveGoalPreference? {
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

        func save(_ item: AdaptiveGoalPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveGoalPreference] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveGoalPreferenceStore(_ inner: MemoryAdaptiveGoalPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveGoalPreferenceStore {
        return CachedAdaptiveGoalPreferenceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive goal preferences. Empty fields match all.
    final class AdaptiveGoalPreferenceQuery {
        var source: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveGoalPreference) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [AdaptiveGoalPreference]) -> [AdaptiveGoalPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveGoalPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveGoalPreferences(_ store: any AdaptiveGoalPreferenceStore, query: AdaptiveGoalPreferenceQuery) -> [AdaptiveGoalPreference] {
        return query.apply(store.list())
    }
}
