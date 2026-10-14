import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps pending authorization preferences by code.
    protocol PendingAuthorizationPreferenceStore {
        func find(_ code: String) -> PendingAuthorizationPreference?
        func save(_ item: PendingAuthorizationPreference)
        func remove(_ code: String) -> Bool
        func list() -> [PendingAuthorizationPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingAuthorizationPreferenceStore: PendingAuthorizationPreferenceStore {
        var items: [String: PendingAuthorizationPreference]
        var order: [String]

        init(items: [String: PendingAuthorizationPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingAuthorizationPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingAuthorizationPreference) {
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

        func list() -> [PendingAuthorizationPreference] {
            var out: [PendingAuthorizationPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingAuthorizationPreferenceStore() -> any PendingAuthorizationPreferenceStore {
        return MemoryPendingAuthorizationPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingAuthorizationPreferenceStore: PendingAuthorizationPreferenceStore {
        var inner: MemoryPendingAuthorizationPreferenceStore
        var cache: TTLCache<PendingAuthorizationPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingAuthorizationPreferenceStore, cache: TTLCache<PendingAuthorizationPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingAuthorizationPreference? {
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

        func save(_ item: PendingAuthorizationPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingAuthorizationPreference] {
            return inner.list()
        }
    }

    static func newCachedPendingAuthorizationPreferenceStore(_ inner: MemoryPendingAuthorizationPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingAuthorizationPreferenceStore {
        return CachedPendingAuthorizationPreferenceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending authorization preferences. Empty fields match all.
    final class PendingAuthorizationPreferenceQuery {
        var category: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingAuthorizationPreference) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [PendingAuthorizationPreference]) -> [PendingAuthorizationPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingAuthorizationPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingAuthorizationPreferences(_ store: any PendingAuthorizationPreferenceStore, query: PendingAuthorizationPreferenceQuery) -> [PendingAuthorizationPreference] {
        return query.apply(store.list())
    }
}
