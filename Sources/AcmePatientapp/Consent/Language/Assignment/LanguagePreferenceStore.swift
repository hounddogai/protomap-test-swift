import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language preferences by code.
    protocol LanguagePreferenceStore {
        func find(_ code: String) -> LanguagePreference?
        func save(_ item: LanguagePreference)
        func remove(_ code: String) -> Bool
        func list() -> [LanguagePreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguagePreferenceStore: LanguagePreferenceStore {
        var items: [String: LanguagePreference]
        var order: [String]

        init(items: [String: LanguagePreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguagePreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguagePreference) {
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

        func list() -> [LanguagePreference] {
            var out: [LanguagePreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguagePreferenceStore() -> any LanguagePreferenceStore {
        return MemoryLanguagePreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguagePreferenceStore: LanguagePreferenceStore {
        var inner: MemoryLanguagePreferenceStore
        var cache: TTLCache<LanguagePreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguagePreferenceStore, cache: TTLCache<LanguagePreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguagePreference? {
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

        func save(_ item: LanguagePreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguagePreference] {
            return inner.list()
        }
    }

    static func newCachedLanguagePreferenceStore(_ inner: MemoryLanguagePreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguagePreferenceStore {
        return CachedLanguagePreferenceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language preferences. Empty fields match all.
    final class LanguagePreferenceQuery {
        var title: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguagePreference) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [LanguagePreference]) -> [LanguagePreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguagePreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguagePreferences(_ store: any LanguagePreferenceStore, query: LanguagePreferenceQuery) -> [LanguagePreference] {
        return query.apply(store.list())
    }
}
