import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps manual network preferences by code.
    protocol ManualNetworkPreferenceStore {
        func find(_ code: String) -> ManualNetworkPreference?
        func save(_ item: ManualNetworkPreference)
        func remove(_ code: String) -> Bool
        func list() -> [ManualNetworkPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualNetworkPreferenceStore: ManualNetworkPreferenceStore {
        var items: [String: ManualNetworkPreference]
        var order: [String]

        init(items: [String: ManualNetworkPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualNetworkPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualNetworkPreference) {
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

        func list() -> [ManualNetworkPreference] {
            var out: [ManualNetworkPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualNetworkPreferenceStore() -> any ManualNetworkPreferenceStore {
        return MemoryManualNetworkPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualNetworkPreferenceStore: ManualNetworkPreferenceStore {
        var inner: MemoryManualNetworkPreferenceStore
        var cache: TTLCache<ManualNetworkPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualNetworkPreferenceStore, cache: TTLCache<ManualNetworkPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualNetworkPreference? {
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

        func save(_ item: ManualNetworkPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualNetworkPreference] {
            return inner.list()
        }
    }

    static func newCachedManualNetworkPreferenceStore(_ inner: MemoryManualNetworkPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualNetworkPreferenceStore {
        return CachedManualNetworkPreferenceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual network preferences. Empty fields match all.
    final class ManualNetworkPreferenceQuery {
        var country: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minLimit: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualNetworkPreference) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualNetworkPreference]) -> [ManualNetworkPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualNetworkPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualNetworkPreferences(_ store: any ManualNetworkPreferenceStore, query: ManualNetworkPreferenceQuery) -> [ManualNetworkPreference] {
        return query.apply(store.list())
    }
}
