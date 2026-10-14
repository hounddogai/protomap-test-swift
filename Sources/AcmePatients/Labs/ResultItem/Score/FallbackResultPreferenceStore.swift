import AcmePlatform
import Foundation

extension Labs {
    /// Keeps fallback result preferences by code.
    protocol FallbackResultPreferenceStore {
        func find(_ code: String) -> FallbackResultPreference?
        func save(_ item: FallbackResultPreference)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackResultPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackResultPreferenceStore: FallbackResultPreferenceStore {
        var items: [String: FallbackResultPreference]
        var order: [String]

        init(items: [String: FallbackResultPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackResultPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackResultPreference) {
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

        func list() -> [FallbackResultPreference] {
            var out: [FallbackResultPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackResultPreferenceStore() -> any FallbackResultPreferenceStore {
        return MemoryFallbackResultPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackResultPreferenceStore: FallbackResultPreferenceStore {
        var inner: MemoryFallbackResultPreferenceStore
        var cache: TTLCache<FallbackResultPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackResultPreferenceStore, cache: TTLCache<FallbackResultPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackResultPreference? {
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

        func save(_ item: FallbackResultPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackResultPreference] {
            return inner.list()
        }
    }

    static func newCachedFallbackResultPreferenceStore(_ inner: MemoryFallbackResultPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackResultPreferenceStore {
        return CachedFallbackResultPreferenceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback result preferences. Empty fields match all.
    final class FallbackResultPreferenceQuery {
        var facility: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackResultPreference) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackResultPreference]) -> [FallbackResultPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackResultPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackResultPreferences(_ store: any FallbackResultPreferenceStore, query: FallbackResultPreferenceQuery) -> [FallbackResultPreference] {
        return query.apply(store.list())
    }
}
