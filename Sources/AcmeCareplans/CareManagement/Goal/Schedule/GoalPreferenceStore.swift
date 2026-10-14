import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal preferences by code.
    protocol GoalPreferenceStore {
        func find(_ code: String) -> GoalPreference?
        func save(_ item: GoalPreference)
        func remove(_ code: String) -> Bool
        func list() -> [GoalPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalPreferenceStore: GoalPreferenceStore {
        var items: [String: GoalPreference]
        var order: [String]

        init(items: [String: GoalPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalPreference) {
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

        func list() -> [GoalPreference] {
            var out: [GoalPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalPreferenceStore() -> any GoalPreferenceStore {
        return MemoryGoalPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalPreferenceStore: GoalPreferenceStore {
        var inner: MemoryGoalPreferenceStore
        var cache: TTLCache<GoalPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalPreferenceStore, cache: TTLCache<GoalPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalPreference? {
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

        func save(_ item: GoalPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalPreference] {
            return inner.list()
        }
    }

    static func newCachedGoalPreferenceStore(_ inner: MemoryGoalPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalPreferenceStore {
        return CachedGoalPreferenceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal preferences. Empty fields match all.
    final class GoalPreferenceQuery {
        var source: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalPreference) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [GoalPreference]) -> [GoalPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalPreferences(_ store: any GoalPreferenceStore, query: GoalPreferenceQuery) -> [GoalPreference] {
        return query.apply(store.list())
    }
}
