import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps rolling statement preferences by code.
    protocol RollingStatementPreferenceStore {
        func find(_ code: String) -> RollingStatementPreference?
        func save(_ item: RollingStatementPreference)
        func remove(_ code: String) -> Bool
        func list() -> [RollingStatementPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingStatementPreferenceStore: RollingStatementPreferenceStore {
        var items: [String: RollingStatementPreference]
        var order: [String]

        init(items: [String: RollingStatementPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingStatementPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingStatementPreference) {
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

        func list() -> [RollingStatementPreference] {
            var out: [RollingStatementPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingStatementPreferenceStore() -> any RollingStatementPreferenceStore {
        return MemoryRollingStatementPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingStatementPreferenceStore: RollingStatementPreferenceStore {
        var inner: MemoryRollingStatementPreferenceStore
        var cache: TTLCache<RollingStatementPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingStatementPreferenceStore, cache: TTLCache<RollingStatementPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingStatementPreference? {
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

        func save(_ item: RollingStatementPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingStatementPreference] {
            return inner.list()
        }
    }

    static func newCachedRollingStatementPreferenceStore(_ inner: MemoryRollingStatementPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingStatementPreferenceStore {
        return CachedRollingStatementPreferenceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling statement preferences. Empty fields match all.
    final class RollingStatementPreferenceQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingStatementPreference) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingStatementPreference]) -> [RollingStatementPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingStatementPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingStatementPreferences(_ store: any RollingStatementPreferenceStore, query: RollingStatementPreferenceQuery) -> [RollingStatementPreference] {
        return query.apply(store.list())
    }
}
