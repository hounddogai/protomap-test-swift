import AcmePlatform
import Foundation

extension Labs {
    /// Keeps legacy panel preferences by code.
    protocol LegacyPanelPreferenceStore {
        func find(_ code: String) -> LegacyPanelPreference?
        func save(_ item: LegacyPanelPreference)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyPanelPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyPanelPreferenceStore: LegacyPanelPreferenceStore {
        var items: [String: LegacyPanelPreference]
        var order: [String]

        init(items: [String: LegacyPanelPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyPanelPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyPanelPreference) {
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

        func list() -> [LegacyPanelPreference] {
            var out: [LegacyPanelPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyPanelPreferenceStore() -> any LegacyPanelPreferenceStore {
        return MemoryLegacyPanelPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyPanelPreferenceStore: LegacyPanelPreferenceStore {
        var inner: MemoryLegacyPanelPreferenceStore
        var cache: TTLCache<LegacyPanelPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyPanelPreferenceStore, cache: TTLCache<LegacyPanelPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyPanelPreference? {
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

        func save(_ item: LegacyPanelPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyPanelPreference] {
            return inner.list()
        }
    }

    static func newCachedLegacyPanelPreferenceStore(_ inner: MemoryLegacyPanelPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyPanelPreferenceStore {
        return CachedLegacyPanelPreferenceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy panel preferences. Empty fields match all.
    final class LegacyPanelPreferenceQuery {
        var facility: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minCopay: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyPanelPreference) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyPanelPreference]) -> [LegacyPanelPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyPanelPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyPanelPreferences(_ store: any LegacyPanelPreferenceStore, query: LegacyPanelPreferenceQuery) -> [LegacyPanelPreference] {
        return query.apply(store.list())
    }
}
