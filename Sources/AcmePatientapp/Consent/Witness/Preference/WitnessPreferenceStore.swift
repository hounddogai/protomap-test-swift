import AcmePlatform
import Foundation

extension Consent {
    /// Keeps witness preferences by code.
    protocol WitnessPreferenceStore {
        func find(_ code: String) -> WitnessPreference?
        func save(_ item: WitnessPreference)
        func remove(_ code: String) -> Bool
        func list() -> [WitnessPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWitnessPreferenceStore: WitnessPreferenceStore {
        var items: [String: WitnessPreference]
        var order: [String]

        init(items: [String: WitnessPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WitnessPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WitnessPreference) {
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

        func list() -> [WitnessPreference] {
            var out: [WitnessPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWitnessPreferenceStore() -> any WitnessPreferenceStore {
        return MemoryWitnessPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWitnessPreferenceStore: WitnessPreferenceStore {
        var inner: MemoryWitnessPreferenceStore
        var cache: TTLCache<WitnessPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryWitnessPreferenceStore, cache: TTLCache<WitnessPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WitnessPreference? {
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

        func save(_ item: WitnessPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WitnessPreference] {
            return inner.list()
        }
    }

    static func newCachedWitnessPreferenceStore(_ inner: MemoryWitnessPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WitnessPreferenceStore {
        return CachedWitnessPreferenceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects witness preferences. Empty fields match all.
    final class WitnessPreferenceQuery {
        var name: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WitnessPreference) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WitnessPreference]) -> [WitnessPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WitnessPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWitnessPreferences(_ store: any WitnessPreferenceStore, query: WitnessPreferenceQuery) -> [WitnessPreference] {
        return query.apply(store.list())
    }
}
