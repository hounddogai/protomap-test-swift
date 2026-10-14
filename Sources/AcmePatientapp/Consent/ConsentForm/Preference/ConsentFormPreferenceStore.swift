import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form preferences by code.
    protocol ConsentFormPreferenceStore {
        func find(_ code: String) -> ConsentFormPreference?
        func save(_ item: ConsentFormPreference)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormPreferenceStore: ConsentFormPreferenceStore {
        var items: [String: ConsentFormPreference]
        var order: [String]

        init(items: [String: ConsentFormPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormPreference) {
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

        func list() -> [ConsentFormPreference] {
            var out: [ConsentFormPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormPreferenceStore() -> any ConsentFormPreferenceStore {
        return MemoryConsentFormPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormPreferenceStore: ConsentFormPreferenceStore {
        var inner: MemoryConsentFormPreferenceStore
        var cache: TTLCache<ConsentFormPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormPreferenceStore, cache: TTLCache<ConsentFormPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormPreference? {
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

        func save(_ item: ConsentFormPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormPreference] {
            return inner.list()
        }
    }

    static func newCachedConsentFormPreferenceStore(_ inner: MemoryConsentFormPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormPreferenceStore {
        return CachedConsentFormPreferenceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form preferences. Empty fields match all.
    final class ConsentFormPreferenceQuery {
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

        func matches(_ item: ConsentFormPreference) -> Bool {
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

        func apply(_ items: [ConsentFormPreference]) -> [ConsentFormPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormPreferences(_ store: any ConsentFormPreferenceStore, query: ConsentFormPreferenceQuery) -> [ConsentFormPreference] {
        return query.apply(store.list())
    }
}
