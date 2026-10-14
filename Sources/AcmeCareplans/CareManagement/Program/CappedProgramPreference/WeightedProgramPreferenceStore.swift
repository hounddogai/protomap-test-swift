import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps weighted program preferences by code.
    protocol WeightedProgramPreferenceStore {
        func find(_ code: String) -> WeightedProgramPreference?
        func save(_ item: WeightedProgramPreference)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedProgramPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedProgramPreferenceStore: WeightedProgramPreferenceStore {
        var items: [String: WeightedProgramPreference]
        var order: [String]

        init(items: [String: WeightedProgramPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedProgramPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedProgramPreference) {
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

        func list() -> [WeightedProgramPreference] {
            var out: [WeightedProgramPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedProgramPreferenceStore() -> any WeightedProgramPreferenceStore {
        return MemoryWeightedProgramPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedProgramPreferenceStore: WeightedProgramPreferenceStore {
        var inner: MemoryWeightedProgramPreferenceStore
        var cache: TTLCache<WeightedProgramPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedProgramPreferenceStore, cache: TTLCache<WeightedProgramPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedProgramPreference? {
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

        func save(_ item: WeightedProgramPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedProgramPreference] {
            return inner.list()
        }
    }

    static func newCachedWeightedProgramPreferenceStore(_ inner: MemoryWeightedProgramPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedProgramPreferenceStore {
        return CachedWeightedProgramPreferenceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted program preferences. Empty fields match all.
    final class WeightedProgramPreferenceQuery {
        var category: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minRatio: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedProgramPreference) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedProgramPreference]) -> [WeightedProgramPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedProgramPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedProgramPreferences(_ store: any WeightedProgramPreferenceStore, query: WeightedProgramPreferenceQuery) -> [WeightedProgramPreference] {
        return query.apply(store.list())
    }
}
