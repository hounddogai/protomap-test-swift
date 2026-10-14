import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps weighted slot preferences by code.
    protocol WeightedSlotPreferenceStore {
        func find(_ code: String) -> WeightedSlotPreference?
        func save(_ item: WeightedSlotPreference)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedSlotPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedSlotPreferenceStore: WeightedSlotPreferenceStore {
        var items: [String: WeightedSlotPreference]
        var order: [String]

        init(items: [String: WeightedSlotPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedSlotPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedSlotPreference) {
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

        func list() -> [WeightedSlotPreference] {
            var out: [WeightedSlotPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedSlotPreferenceStore() -> any WeightedSlotPreferenceStore {
        return MemoryWeightedSlotPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedSlotPreferenceStore: WeightedSlotPreferenceStore {
        var inner: MemoryWeightedSlotPreferenceStore
        var cache: TTLCache<WeightedSlotPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedSlotPreferenceStore, cache: TTLCache<WeightedSlotPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedSlotPreference? {
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

        func save(_ item: WeightedSlotPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedSlotPreference] {
            return inner.list()
        }
    }

    static func newCachedWeightedSlotPreferenceStore(_ inner: MemoryWeightedSlotPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedSlotPreferenceStore {
        return CachedWeightedSlotPreferenceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted slot preferences. Empty fields match all.
    final class WeightedSlotPreferenceQuery {
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

        func matches(_ item: WeightedSlotPreference) -> Bool {
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

        func apply(_ items: [WeightedSlotPreference]) -> [WeightedSlotPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedSlotPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedSlotPreferences(_ store: any WeightedSlotPreferenceStore, query: WeightedSlotPreferenceQuery) -> [WeightedSlotPreference] {
        return query.apply(store.list())
    }
}
