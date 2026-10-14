import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps seasonal worklist preferences by code.
    protocol SeasonalWorklistPreferenceStore {
        func find(_ code: String) -> SeasonalWorklistPreference?
        func save(_ item: SeasonalWorklistPreference)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalWorklistPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalWorklistPreferenceStore: SeasonalWorklistPreferenceStore {
        var items: [String: SeasonalWorklistPreference]
        var order: [String]

        init(items: [String: SeasonalWorklistPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalWorklistPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalWorklistPreference) {
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

        func list() -> [SeasonalWorklistPreference] {
            var out: [SeasonalWorklistPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalWorklistPreferenceStore() -> any SeasonalWorklistPreferenceStore {
        return MemorySeasonalWorklistPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalWorklistPreferenceStore: SeasonalWorklistPreferenceStore {
        var inner: MemorySeasonalWorklistPreferenceStore
        var cache: TTLCache<SeasonalWorklistPreference>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalWorklistPreferenceStore, cache: TTLCache<SeasonalWorklistPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalWorklistPreference? {
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

        func save(_ item: SeasonalWorklistPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalWorklistPreference] {
            return inner.list()
        }
    }

    static func newCachedSeasonalWorklistPreferenceStore(_ inner: MemorySeasonalWorklistPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalWorklistPreferenceStore {
        return CachedSeasonalWorklistPreferenceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal worklist preferences. Empty fields match all.
    final class SeasonalWorklistPreferenceQuery {
        var channel: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalWorklistPreference) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [SeasonalWorklistPreference]) -> [SeasonalWorklistPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalWorklistPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalWorklistPreferences(_ store: any SeasonalWorklistPreferenceStore, query: SeasonalWorklistPreferenceQuery) -> [SeasonalWorklistPreference] {
        return query.apply(store.list())
    }
}
