import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps lenient risk score preferences by code.
    protocol LenientRiskScorePreferenceStore {
        func find(_ code: String) -> LenientRiskScorePreference?
        func save(_ item: LenientRiskScorePreference)
        func remove(_ code: String) -> Bool
        func list() -> [LenientRiskScorePreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientRiskScorePreferenceStore: LenientRiskScorePreferenceStore {
        var items: [String: LenientRiskScorePreference]
        var order: [String]

        init(items: [String: LenientRiskScorePreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientRiskScorePreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientRiskScorePreference) {
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

        func list() -> [LenientRiskScorePreference] {
            var out: [LenientRiskScorePreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientRiskScorePreferenceStore() -> any LenientRiskScorePreferenceStore {
        return MemoryLenientRiskScorePreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientRiskScorePreferenceStore: LenientRiskScorePreferenceStore {
        var inner: MemoryLenientRiskScorePreferenceStore
        var cache: TTLCache<LenientRiskScorePreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientRiskScorePreferenceStore, cache: TTLCache<LenientRiskScorePreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientRiskScorePreference? {
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

        func save(_ item: LenientRiskScorePreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientRiskScorePreference] {
            return inner.list()
        }
    }

    static func newCachedLenientRiskScorePreferenceStore(_ inner: MemoryLenientRiskScorePreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientRiskScorePreferenceStore {
        return CachedLenientRiskScorePreferenceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient risk score preferences. Empty fields match all.
    final class LenientRiskScorePreferenceQuery {
        var title: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientRiskScorePreference) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [LenientRiskScorePreference]) -> [LenientRiskScorePreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientRiskScorePreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientRiskScorePreferences(_ store: any LenientRiskScorePreferenceStore, query: LenientRiskScorePreferenceQuery) -> [LenientRiskScorePreference] {
        return query.apply(store.list())
    }
}
