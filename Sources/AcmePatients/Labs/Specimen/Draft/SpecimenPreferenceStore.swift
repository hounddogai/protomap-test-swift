import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen preferences by code.
    protocol SpecimenPreferenceStore {
        func find(_ code: String) -> SpecimenPreference?
        func save(_ item: SpecimenPreference)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenPreferenceStore: SpecimenPreferenceStore {
        var items: [String: SpecimenPreference]
        var order: [String]

        init(items: [String: SpecimenPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenPreference) {
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

        func list() -> [SpecimenPreference] {
            var out: [SpecimenPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenPreferenceStore() -> any SpecimenPreferenceStore {
        return MemorySpecimenPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenPreferenceStore: SpecimenPreferenceStore {
        var inner: MemorySpecimenPreferenceStore
        var cache: TTLCache<SpecimenPreference>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenPreferenceStore, cache: TTLCache<SpecimenPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenPreference? {
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

        func save(_ item: SpecimenPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenPreference] {
            return inner.list()
        }
    }

    static func newCachedSpecimenPreferenceStore(_ inner: MemorySpecimenPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenPreferenceStore {
        return CachedSpecimenPreferenceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen preferences. Empty fields match all.
    final class SpecimenPreferenceQuery {
        var label: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenPreference) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [SpecimenPreference]) -> [SpecimenPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenPreferences(_ store: any SpecimenPreferenceStore, query: SpecimenPreferenceQuery) -> [SpecimenPreference] {
        return query.apply(store.list())
    }
}
