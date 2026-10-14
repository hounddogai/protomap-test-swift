import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps capped modality preferences by code.
    protocol CappedModalityPreferenceStore {
        func find(_ code: String) -> CappedModalityPreference?
        func save(_ item: CappedModalityPreference)
        func remove(_ code: String) -> Bool
        func list() -> [CappedModalityPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedModalityPreferenceStore: CappedModalityPreferenceStore {
        var items: [String: CappedModalityPreference]
        var order: [String]

        init(items: [String: CappedModalityPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedModalityPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedModalityPreference) {
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

        func list() -> [CappedModalityPreference] {
            var out: [CappedModalityPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedModalityPreferenceStore() -> any CappedModalityPreferenceStore {
        return MemoryCappedModalityPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedModalityPreferenceStore: CappedModalityPreferenceStore {
        var inner: MemoryCappedModalityPreferenceStore
        var cache: TTLCache<CappedModalityPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedModalityPreferenceStore, cache: TTLCache<CappedModalityPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedModalityPreference? {
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

        func save(_ item: CappedModalityPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedModalityPreference] {
            return inner.list()
        }
    }

    static func newCachedCappedModalityPreferenceStore(_ inner: MemoryCappedModalityPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedModalityPreferenceStore {
        return CachedCappedModalityPreferenceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped modality preferences. Empty fields match all.
    final class CappedModalityPreferenceQuery {
        var unit: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minBudget: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedModalityPreference) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedModalityPreference]) -> [CappedModalityPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedModalityPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedModalityPreferences(_ store: any CappedModalityPreferenceStore, query: CappedModalityPreferenceQuery) -> [CappedModalityPreference] {
        return query.apply(store.list())
    }
}
