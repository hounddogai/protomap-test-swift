import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps weighted rounding preferences by code.
    protocol WeightedRoundingPreferenceStore {
        func find(_ code: String) -> WeightedRoundingPreference?
        func save(_ item: WeightedRoundingPreference)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedRoundingPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedRoundingPreferenceStore: WeightedRoundingPreferenceStore {
        var items: [String: WeightedRoundingPreference]
        var order: [String]

        init(items: [String: WeightedRoundingPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedRoundingPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedRoundingPreference) {
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

        func list() -> [WeightedRoundingPreference] {
            var out: [WeightedRoundingPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedRoundingPreferenceStore() -> any WeightedRoundingPreferenceStore {
        return MemoryWeightedRoundingPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedRoundingPreferenceStore: WeightedRoundingPreferenceStore {
        var inner: MemoryWeightedRoundingPreferenceStore
        var cache: TTLCache<WeightedRoundingPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedRoundingPreferenceStore, cache: TTLCache<WeightedRoundingPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedRoundingPreference? {
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

        func save(_ item: WeightedRoundingPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedRoundingPreference] {
            return inner.list()
        }
    }

    static func newCachedWeightedRoundingPreferenceStore(_ inner: MemoryWeightedRoundingPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedRoundingPreferenceStore {
        return CachedWeightedRoundingPreferenceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted rounding preferences. Empty fields match all.
    final class WeightedRoundingPreferenceQuery {
        var region: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedRoundingPreference) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [WeightedRoundingPreference]) -> [WeightedRoundingPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedRoundingPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedRoundingPreferences(_ store: any WeightedRoundingPreferenceStore, query: WeightedRoundingPreferenceQuery) -> [WeightedRoundingPreference] {
        return query.apply(store.list())
    }
}
