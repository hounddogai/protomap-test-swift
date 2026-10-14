import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility preferences by code.
    protocol EligibilityPreferenceStore {
        func find(_ code: String) -> EligibilityPreference?
        func save(_ item: EligibilityPreference)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityPreferenceStore: EligibilityPreferenceStore {
        var items: [String: EligibilityPreference]
        var order: [String]

        init(items: [String: EligibilityPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityPreference) {
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

        func list() -> [EligibilityPreference] {
            var out: [EligibilityPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityPreferenceStore() -> any EligibilityPreferenceStore {
        return MemoryEligibilityPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityPreferenceStore: EligibilityPreferenceStore {
        var inner: MemoryEligibilityPreferenceStore
        var cache: TTLCache<EligibilityPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityPreferenceStore, cache: TTLCache<EligibilityPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityPreference? {
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

        func save(_ item: EligibilityPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityPreference] {
            return inner.list()
        }
    }

    static func newCachedEligibilityPreferenceStore(_ inner: MemoryEligibilityPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityPreferenceStore {
        return CachedEligibilityPreferenceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility preferences. Empty fields match all.
    final class EligibilityPreferenceQuery {
        var name: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilityPreference) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [EligibilityPreference]) -> [EligibilityPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityPreferences(_ store: any EligibilityPreferenceStore, query: EligibilityPreferenceQuery) -> [EligibilityPreference] {
        return query.apply(store.list())
    }
}
