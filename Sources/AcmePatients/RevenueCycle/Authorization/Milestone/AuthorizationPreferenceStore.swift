import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization preferences by code.
    protocol AuthorizationPreferenceStore {
        func find(_ code: String) -> AuthorizationPreference?
        func save(_ item: AuthorizationPreference)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationPreferenceStore: AuthorizationPreferenceStore {
        var items: [String: AuthorizationPreference]
        var order: [String]

        init(items: [String: AuthorizationPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationPreference) {
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

        func list() -> [AuthorizationPreference] {
            var out: [AuthorizationPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationPreferenceStore() -> any AuthorizationPreferenceStore {
        return MemoryAuthorizationPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationPreferenceStore: AuthorizationPreferenceStore {
        var inner: MemoryAuthorizationPreferenceStore
        var cache: TTLCache<AuthorizationPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationPreferenceStore, cache: TTLCache<AuthorizationPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationPreference? {
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

        func save(_ item: AuthorizationPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationPreference] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationPreferenceStore(_ inner: MemoryAuthorizationPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationPreferenceStore {
        return CachedAuthorizationPreferenceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization preferences. Empty fields match all.
    final class AuthorizationPreferenceQuery {
        var label: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationPreference) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationPreference]) -> [AuthorizationPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationPreferences(_ store: any AuthorizationPreferenceStore, query: AuthorizationPreferenceQuery) -> [AuthorizationPreference] {
        return query.apply(store.list())
    }
}
