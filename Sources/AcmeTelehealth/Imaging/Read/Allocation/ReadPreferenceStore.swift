import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read preferences by code.
    protocol ReadPreferenceStore {
        func find(_ code: String) -> ReadPreference?
        func save(_ item: ReadPreference)
        func remove(_ code: String) -> Bool
        func list() -> [ReadPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadPreferenceStore: ReadPreferenceStore {
        var items: [String: ReadPreference]
        var order: [String]

        init(items: [String: ReadPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadPreference) {
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

        func list() -> [ReadPreference] {
            var out: [ReadPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadPreferenceStore() -> any ReadPreferenceStore {
        return MemoryReadPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadPreferenceStore: ReadPreferenceStore {
        var inner: MemoryReadPreferenceStore
        var cache: TTLCache<ReadPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadPreferenceStore, cache: TTLCache<ReadPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadPreference? {
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

        func save(_ item: ReadPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadPreference] {
            return inner.list()
        }
    }

    static func newCachedReadPreferenceStore(_ inner: MemoryReadPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadPreferenceStore {
        return CachedReadPreferenceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects read preferences. Empty fields match all.
    final class ReadPreferenceQuery {
        var region: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadPreference) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReadPreference]) -> [ReadPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadPreferences(_ store: any ReadPreferenceStore, query: ReadPreferenceQuery) -> [ReadPreference] {
        return query.apply(store.list())
    }
}
