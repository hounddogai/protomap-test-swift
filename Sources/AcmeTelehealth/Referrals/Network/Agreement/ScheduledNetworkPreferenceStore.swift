import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps scheduled network preferences by code.
    protocol ScheduledNetworkPreferenceStore {
        func find(_ code: String) -> ScheduledNetworkPreference?
        func save(_ item: ScheduledNetworkPreference)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledNetworkPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledNetworkPreferenceStore: ScheduledNetworkPreferenceStore {
        var items: [String: ScheduledNetworkPreference]
        var order: [String]

        init(items: [String: ScheduledNetworkPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledNetworkPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledNetworkPreference) {
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

        func list() -> [ScheduledNetworkPreference] {
            var out: [ScheduledNetworkPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledNetworkPreferenceStore() -> any ScheduledNetworkPreferenceStore {
        return MemoryScheduledNetworkPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledNetworkPreferenceStore: ScheduledNetworkPreferenceStore {
        var inner: MemoryScheduledNetworkPreferenceStore
        var cache: TTLCache<ScheduledNetworkPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledNetworkPreferenceStore, cache: TTLCache<ScheduledNetworkPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledNetworkPreference? {
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

        func save(_ item: ScheduledNetworkPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledNetworkPreference] {
            return inner.list()
        }
    }

    static func newCachedScheduledNetworkPreferenceStore(_ inner: MemoryScheduledNetworkPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledNetworkPreferenceStore {
        return CachedScheduledNetworkPreferenceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled network preferences. Empty fields match all.
    final class ScheduledNetworkPreferenceQuery {
        var locale: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledNetworkPreference) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledNetworkPreference]) -> [ScheduledNetworkPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledNetworkPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledNetworkPreferences(_ store: any ScheduledNetworkPreferenceStore, query: ScheduledNetworkPreferenceQuery) -> [ScheduledNetworkPreference] {
        return query.apply(store.list())
    }
}
