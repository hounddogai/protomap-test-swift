import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps rolling isolation preferences by code.
    protocol RollingIsolationPreferenceStore {
        func find(_ code: String) -> RollingIsolationPreference?
        func save(_ item: RollingIsolationPreference)
        func remove(_ code: String) -> Bool
        func list() -> [RollingIsolationPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingIsolationPreferenceStore: RollingIsolationPreferenceStore {
        var items: [String: RollingIsolationPreference]
        var order: [String]

        init(items: [String: RollingIsolationPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingIsolationPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingIsolationPreference) {
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

        func list() -> [RollingIsolationPreference] {
            var out: [RollingIsolationPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingIsolationPreferenceStore() -> any RollingIsolationPreferenceStore {
        return MemoryRollingIsolationPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingIsolationPreferenceStore: RollingIsolationPreferenceStore {
        var inner: MemoryRollingIsolationPreferenceStore
        var cache: TTLCache<RollingIsolationPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingIsolationPreferenceStore, cache: TTLCache<RollingIsolationPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingIsolationPreference? {
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

        func save(_ item: RollingIsolationPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingIsolationPreference] {
            return inner.list()
        }
    }

    static func newCachedRollingIsolationPreferenceStore(_ inner: MemoryRollingIsolationPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingIsolationPreferenceStore {
        return CachedRollingIsolationPreferenceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling isolation preferences. Empty fields match all.
    final class RollingIsolationPreferenceQuery {
        var locale: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minCost: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingIsolationPreference) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingIsolationPreference]) -> [RollingIsolationPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingIsolationPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingIsolationPreferences(_ store: any RollingIsolationPreferenceStore, query: RollingIsolationPreferenceQuery) -> [RollingIsolationPreference] {
        return query.apply(store.list())
    }
}
