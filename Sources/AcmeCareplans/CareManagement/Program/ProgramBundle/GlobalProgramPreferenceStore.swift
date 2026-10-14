import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps global program preferences by code.
    protocol GlobalProgramPreferenceStore {
        func find(_ code: String) -> GlobalProgramPreference?
        func save(_ item: GlobalProgramPreference)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalProgramPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalProgramPreferenceStore: GlobalProgramPreferenceStore {
        var items: [String: GlobalProgramPreference]
        var order: [String]

        init(items: [String: GlobalProgramPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalProgramPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalProgramPreference) {
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

        func list() -> [GlobalProgramPreference] {
            var out: [GlobalProgramPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalProgramPreferenceStore() -> any GlobalProgramPreferenceStore {
        return MemoryGlobalProgramPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalProgramPreferenceStore: GlobalProgramPreferenceStore {
        var inner: MemoryGlobalProgramPreferenceStore
        var cache: TTLCache<GlobalProgramPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalProgramPreferenceStore, cache: TTLCache<GlobalProgramPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalProgramPreference? {
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

        func save(_ item: GlobalProgramPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalProgramPreference] {
            return inner.list()
        }
    }

    static func newCachedGlobalProgramPreferenceStore(_ inner: MemoryGlobalProgramPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalProgramPreferenceStore {
        return CachedGlobalProgramPreferenceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global program preferences. Empty fields match all.
    final class GlobalProgramPreferenceQuery {
        var country: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minRate: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalProgramPreference) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalProgramPreference]) -> [GlobalProgramPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalProgramPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalProgramPreferences(_ store: any GlobalProgramPreferenceStore, query: GlobalProgramPreferenceQuery) -> [GlobalProgramPreference] {
        return query.apply(store.list())
    }
}
