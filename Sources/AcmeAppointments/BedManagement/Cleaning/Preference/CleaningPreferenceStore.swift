import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning preferences by code.
    protocol CleaningPreferenceStore {
        func find(_ code: String) -> CleaningPreference?
        func save(_ item: CleaningPreference)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningPreferenceStore: CleaningPreferenceStore {
        var items: [String: CleaningPreference]
        var order: [String]

        init(items: [String: CleaningPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningPreference) {
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

        func list() -> [CleaningPreference] {
            var out: [CleaningPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningPreferenceStore() -> any CleaningPreferenceStore {
        return MemoryCleaningPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningPreferenceStore: CleaningPreferenceStore {
        var inner: MemoryCleaningPreferenceStore
        var cache: TTLCache<CleaningPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningPreferenceStore, cache: TTLCache<CleaningPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningPreference? {
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

        func save(_ item: CleaningPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningPreference] {
            return inner.list()
        }
    }

    static func newCachedCleaningPreferenceStore(_ inner: MemoryCleaningPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningPreferenceStore {
        return CachedCleaningPreferenceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning preferences. Empty fields match all.
    final class CleaningPreferenceQuery {
        var country: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minCopay: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningPreference) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningPreference]) -> [CleaningPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningPreferences(_ store: any CleaningPreferenceStore, query: CleaningPreferenceQuery) -> [CleaningPreference] {
        return query.apply(store.list())
    }
}
