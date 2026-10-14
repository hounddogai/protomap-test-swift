import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps strict task preferences by code.
    protocol StrictTaskPreferenceStore {
        func find(_ code: String) -> StrictTaskPreference?
        func save(_ item: StrictTaskPreference)
        func remove(_ code: String) -> Bool
        func list() -> [StrictTaskPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictTaskPreferenceStore: StrictTaskPreferenceStore {
        var items: [String: StrictTaskPreference]
        var order: [String]

        init(items: [String: StrictTaskPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictTaskPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictTaskPreference) {
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

        func list() -> [StrictTaskPreference] {
            var out: [StrictTaskPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictTaskPreferenceStore() -> any StrictTaskPreferenceStore {
        return MemoryStrictTaskPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictTaskPreferenceStore: StrictTaskPreferenceStore {
        var inner: MemoryStrictTaskPreferenceStore
        var cache: TTLCache<StrictTaskPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictTaskPreferenceStore, cache: TTLCache<StrictTaskPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictTaskPreference? {
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

        func save(_ item: StrictTaskPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictTaskPreference] {
            return inner.list()
        }
    }

    static func newCachedStrictTaskPreferenceStore(_ inner: MemoryStrictTaskPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictTaskPreferenceStore {
        return CachedStrictTaskPreferenceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict task preferences. Empty fields match all.
    final class StrictTaskPreferenceQuery {
        var label: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictTaskPreference) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictTaskPreference]) -> [StrictTaskPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictTaskPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictTaskPreferences(_ store: any StrictTaskPreferenceStore, query: StrictTaskPreferenceQuery) -> [StrictTaskPreference] {
        return query.apply(store.list())
    }
}
