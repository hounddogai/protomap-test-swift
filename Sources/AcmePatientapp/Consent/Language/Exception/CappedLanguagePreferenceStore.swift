import AcmePlatform
import Foundation

extension Consent {
    /// Keeps capped language preferences by code.
    protocol CappedLanguagePreferenceStore {
        func find(_ code: String) -> CappedLanguagePreference?
        func save(_ item: CappedLanguagePreference)
        func remove(_ code: String) -> Bool
        func list() -> [CappedLanguagePreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedLanguagePreferenceStore: CappedLanguagePreferenceStore {
        var items: [String: CappedLanguagePreference]
        var order: [String]

        init(items: [String: CappedLanguagePreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedLanguagePreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedLanguagePreference) {
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

        func list() -> [CappedLanguagePreference] {
            var out: [CappedLanguagePreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedLanguagePreferenceStore() -> any CappedLanguagePreferenceStore {
        return MemoryCappedLanguagePreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedLanguagePreferenceStore: CappedLanguagePreferenceStore {
        var inner: MemoryCappedLanguagePreferenceStore
        var cache: TTLCache<CappedLanguagePreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedLanguagePreferenceStore, cache: TTLCache<CappedLanguagePreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedLanguagePreference? {
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

        func save(_ item: CappedLanguagePreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedLanguagePreference] {
            return inner.list()
        }
    }

    static func newCachedCappedLanguagePreferenceStore(_ inner: MemoryCappedLanguagePreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedLanguagePreferenceStore {
        return CachedCappedLanguagePreferenceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped language preferences. Empty fields match all.
    final class CappedLanguagePreferenceQuery {
        var label: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minWeight: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedLanguagePreference) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedLanguagePreference]) -> [CappedLanguagePreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedLanguagePreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedLanguagePreferences(_ store: any CappedLanguagePreferenceStore, query: CappedLanguagePreferenceQuery) -> [CappedLanguagePreference] {
        return query.apply(store.list())
    }
}
