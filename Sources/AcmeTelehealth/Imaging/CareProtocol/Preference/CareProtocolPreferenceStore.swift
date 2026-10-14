import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol preferences by code.
    protocol CareProtocolPreferenceStore {
        func find(_ code: String) -> CareProtocolPreference?
        func save(_ item: CareProtocolPreference)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolPreferenceStore: CareProtocolPreferenceStore {
        var items: [String: CareProtocolPreference]
        var order: [String]

        init(items: [String: CareProtocolPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolPreference) {
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

        func list() -> [CareProtocolPreference] {
            var out: [CareProtocolPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolPreferenceStore() -> any CareProtocolPreferenceStore {
        return MemoryCareProtocolPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolPreferenceStore: CareProtocolPreferenceStore {
        var inner: MemoryCareProtocolPreferenceStore
        var cache: TTLCache<CareProtocolPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolPreferenceStore, cache: TTLCache<CareProtocolPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolPreference? {
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

        func save(_ item: CareProtocolPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolPreference] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolPreferenceStore(_ inner: MemoryCareProtocolPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolPreferenceStore {
        return CachedCareProtocolPreferenceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol preferences. Empty fields match all.
    final class CareProtocolPreferenceQuery {
        var name: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRefills: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolPreference) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [CareProtocolPreference]) -> [CareProtocolPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolPreferences(_ store: any CareProtocolPreferenceStore, query: CareProtocolPreferenceQuery) -> [CareProtocolPreference] {
        return query.apply(store.list())
    }
}
