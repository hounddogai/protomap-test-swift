import AcmePlatform
import Foundation

extension Consent {
    /// Keeps fallback revocation preferences by code.
    protocol FallbackRevocationPreferenceStore {
        func find(_ code: String) -> FallbackRevocationPreference?
        func save(_ item: FallbackRevocationPreference)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackRevocationPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackRevocationPreferenceStore: FallbackRevocationPreferenceStore {
        var items: [String: FallbackRevocationPreference]
        var order: [String]

        init(items: [String: FallbackRevocationPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackRevocationPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackRevocationPreference) {
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

        func list() -> [FallbackRevocationPreference] {
            var out: [FallbackRevocationPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackRevocationPreferenceStore() -> any FallbackRevocationPreferenceStore {
        return MemoryFallbackRevocationPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackRevocationPreferenceStore: FallbackRevocationPreferenceStore {
        var inner: MemoryFallbackRevocationPreferenceStore
        var cache: TTLCache<FallbackRevocationPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackRevocationPreferenceStore, cache: TTLCache<FallbackRevocationPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackRevocationPreference? {
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

        func save(_ item: FallbackRevocationPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackRevocationPreference] {
            return inner.list()
        }
    }

    static func newCachedFallbackRevocationPreferenceStore(_ inner: MemoryFallbackRevocationPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackRevocationPreferenceStore {
        return CachedFallbackRevocationPreferenceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback revocation preferences. Empty fields match all.
    final class FallbackRevocationPreferenceQuery {
        var country: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackRevocationPreference) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackRevocationPreference]) -> [FallbackRevocationPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackRevocationPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackRevocationPreferences(_ store: any FallbackRevocationPreferenceStore, query: FallbackRevocationPreferenceQuery) -> [FallbackRevocationPreference] {
        return query.apply(store.list())
    }
}
