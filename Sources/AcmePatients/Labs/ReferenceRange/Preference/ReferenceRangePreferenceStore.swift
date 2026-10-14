import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range preferences by code.
    protocol ReferenceRangePreferenceStore {
        func find(_ code: String) -> ReferenceRangePreference?
        func save(_ item: ReferenceRangePreference)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangePreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangePreferenceStore: ReferenceRangePreferenceStore {
        var items: [String: ReferenceRangePreference]
        var order: [String]

        init(items: [String: ReferenceRangePreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangePreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangePreference) {
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

        func list() -> [ReferenceRangePreference] {
            var out: [ReferenceRangePreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangePreferenceStore() -> any ReferenceRangePreferenceStore {
        return MemoryReferenceRangePreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangePreferenceStore: ReferenceRangePreferenceStore {
        var inner: MemoryReferenceRangePreferenceStore
        var cache: TTLCache<ReferenceRangePreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangePreferenceStore, cache: TTLCache<ReferenceRangePreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangePreference? {
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

        func save(_ item: ReferenceRangePreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangePreference] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangePreferenceStore(_ inner: MemoryReferenceRangePreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangePreferenceStore {
        return CachedReferenceRangePreferenceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range preferences. Empty fields match all.
    final class ReferenceRangePreferenceQuery {
        var locale: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minScore: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangePreference) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferenceRangePreference]) -> [ReferenceRangePreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangePreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangePreferences(_ store: any ReferenceRangePreferenceStore, query: ReferenceRangePreferenceQuery) -> [ReferenceRangePreference] {
        return query.apply(store.list())
    }
}
