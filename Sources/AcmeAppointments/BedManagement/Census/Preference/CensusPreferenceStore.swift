import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps census preferences by code.
    protocol CensusPreferenceStore {
        func find(_ code: String) -> CensusPreference?
        func save(_ item: CensusPreference)
        func remove(_ code: String) -> Bool
        func list() -> [CensusPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCensusPreferenceStore: CensusPreferenceStore {
        var items: [String: CensusPreference]
        var order: [String]

        init(items: [String: CensusPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CensusPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CensusPreference) {
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

        func list() -> [CensusPreference] {
            var out: [CensusPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCensusPreferenceStore() -> any CensusPreferenceStore {
        return MemoryCensusPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCensusPreferenceStore: CensusPreferenceStore {
        var inner: MemoryCensusPreferenceStore
        var cache: TTLCache<CensusPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryCensusPreferenceStore, cache: TTLCache<CensusPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CensusPreference? {
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

        func save(_ item: CensusPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CensusPreference] {
            return inner.list()
        }
    }

    static func newCachedCensusPreferenceStore(_ inner: MemoryCensusPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CensusPreferenceStore {
        return CachedCensusPreferenceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects census preferences. Empty fields match all.
    final class CensusPreferenceQuery {
        var ward: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CensusPreference) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [CensusPreference]) -> [CensusPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CensusPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCensusPreferences(_ store: any CensusPreferenceStore, query: CensusPreferenceQuery) -> [CensusPreference] {
        return query.apply(store.list())
    }
}
