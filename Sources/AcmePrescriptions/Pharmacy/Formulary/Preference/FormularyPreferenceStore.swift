import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps formulary preferences by code.
    protocol FormularyPreferenceStore {
        func find(_ code: String) -> FormularyPreference?
        func save(_ item: FormularyPreference)
        func remove(_ code: String) -> Bool
        func list() -> [FormularyPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFormularyPreferenceStore: FormularyPreferenceStore {
        var items: [String: FormularyPreference]
        var order: [String]

        init(items: [String: FormularyPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FormularyPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FormularyPreference) {
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

        func list() -> [FormularyPreference] {
            var out: [FormularyPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFormularyPreferenceStore() -> any FormularyPreferenceStore {
        return MemoryFormularyPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFormularyPreferenceStore: FormularyPreferenceStore {
        var inner: MemoryFormularyPreferenceStore
        var cache: TTLCache<FormularyPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryFormularyPreferenceStore, cache: TTLCache<FormularyPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FormularyPreference? {
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

        func save(_ item: FormularyPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FormularyPreference] {
            return inner.list()
        }
    }

    static func newCachedFormularyPreferenceStore(_ inner: MemoryFormularyPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FormularyPreferenceStore {
        return CachedFormularyPreferenceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects formulary preferences. Empty fields match all.
    final class FormularyPreferenceQuery {
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

        func matches(_ item: FormularyPreference) -> Bool {
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

        func apply(_ items: [FormularyPreference]) -> [FormularyPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FormularyPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFormularyPreferences(_ store: any FormularyPreferenceStore, query: FormularyPreferenceQuery) -> [FormularyPreference] {
        return query.apply(store.list())
    }
}
