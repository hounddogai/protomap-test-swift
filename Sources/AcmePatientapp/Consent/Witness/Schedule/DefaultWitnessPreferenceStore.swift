import AcmePlatform
import Foundation

extension Consent {
    /// Keeps default witness preferences by code.
    protocol DefaultWitnessPreferenceStore {
        func find(_ code: String) -> DefaultWitnessPreference?
        func save(_ item: DefaultWitnessPreference)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultWitnessPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultWitnessPreferenceStore: DefaultWitnessPreferenceStore {
        var items: [String: DefaultWitnessPreference]
        var order: [String]

        init(items: [String: DefaultWitnessPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultWitnessPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultWitnessPreference) {
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

        func list() -> [DefaultWitnessPreference] {
            var out: [DefaultWitnessPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultWitnessPreferenceStore() -> any DefaultWitnessPreferenceStore {
        return MemoryDefaultWitnessPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultWitnessPreferenceStore: DefaultWitnessPreferenceStore {
        var inner: MemoryDefaultWitnessPreferenceStore
        var cache: TTLCache<DefaultWitnessPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultWitnessPreferenceStore, cache: TTLCache<DefaultWitnessPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultWitnessPreference? {
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

        func save(_ item: DefaultWitnessPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultWitnessPreference] {
            return inner.list()
        }
    }

    static func newCachedDefaultWitnessPreferenceStore(_ inner: MemoryDefaultWitnessPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultWitnessPreferenceStore {
        return CachedDefaultWitnessPreferenceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default witness preferences. Empty fields match all.
    final class DefaultWitnessPreferenceQuery {
        var ward: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minRefills: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultWitnessPreference) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultWitnessPreference]) -> [DefaultWitnessPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultWitnessPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultWitnessPreferences(_ store: any DefaultWitnessPreferenceStore, query: DefaultWitnessPreferenceQuery) -> [DefaultWitnessPreference] {
        return query.apply(store.list())
    }
}
