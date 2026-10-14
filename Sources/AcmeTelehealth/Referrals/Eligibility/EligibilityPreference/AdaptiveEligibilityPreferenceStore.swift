import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps adaptive eligibility preferences by code.
    protocol AdaptiveEligibilityPreferenceStore {
        func find(_ code: String) -> AdaptiveEligibilityPreference?
        func save(_ item: AdaptiveEligibilityPreference)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveEligibilityPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveEligibilityPreferenceStore: AdaptiveEligibilityPreferenceStore {
        var items: [String: AdaptiveEligibilityPreference]
        var order: [String]

        init(items: [String: AdaptiveEligibilityPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveEligibilityPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveEligibilityPreference) {
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

        func list() -> [AdaptiveEligibilityPreference] {
            var out: [AdaptiveEligibilityPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveEligibilityPreferenceStore() -> any AdaptiveEligibilityPreferenceStore {
        return MemoryAdaptiveEligibilityPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveEligibilityPreferenceStore: AdaptiveEligibilityPreferenceStore {
        var inner: MemoryAdaptiveEligibilityPreferenceStore
        var cache: TTLCache<AdaptiveEligibilityPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveEligibilityPreferenceStore, cache: TTLCache<AdaptiveEligibilityPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveEligibilityPreference? {
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

        func save(_ item: AdaptiveEligibilityPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveEligibilityPreference] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveEligibilityPreferenceStore(_ inner: MemoryAdaptiveEligibilityPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveEligibilityPreferenceStore {
        return CachedAdaptiveEligibilityPreferenceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive eligibility preferences. Empty fields match all.
    final class AdaptiveEligibilityPreferenceQuery {
        var country: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minSequence: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveEligibilityPreference) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveEligibilityPreference]) -> [AdaptiveEligibilityPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveEligibilityPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveEligibilityPreferences(_ store: any AdaptiveEligibilityPreferenceStore, query: AdaptiveEligibilityPreferenceQuery) -> [AdaptiveEligibilityPreference] {
        return query.apply(store.list())
    }
}
