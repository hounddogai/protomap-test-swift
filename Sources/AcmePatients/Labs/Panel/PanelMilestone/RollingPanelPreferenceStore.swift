import AcmePlatform
import Foundation

extension Labs {
    /// Keeps rolling panel preferences by code.
    protocol RollingPanelPreferenceStore {
        func find(_ code: String) -> RollingPanelPreference?
        func save(_ item: RollingPanelPreference)
        func remove(_ code: String) -> Bool
        func list() -> [RollingPanelPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingPanelPreferenceStore: RollingPanelPreferenceStore {
        var items: [String: RollingPanelPreference]
        var order: [String]

        init(items: [String: RollingPanelPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingPanelPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingPanelPreference) {
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

        func list() -> [RollingPanelPreference] {
            var out: [RollingPanelPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingPanelPreferenceStore() -> any RollingPanelPreferenceStore {
        return MemoryRollingPanelPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingPanelPreferenceStore: RollingPanelPreferenceStore {
        var inner: MemoryRollingPanelPreferenceStore
        var cache: TTLCache<RollingPanelPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingPanelPreferenceStore, cache: TTLCache<RollingPanelPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingPanelPreference? {
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

        func save(_ item: RollingPanelPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingPanelPreference] {
            return inner.list()
        }
    }

    static func newCachedRollingPanelPreferenceStore(_ inner: MemoryRollingPanelPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingPanelPreferenceStore {
        return CachedRollingPanelPreferenceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling panel preferences. Empty fields match all.
    final class RollingPanelPreferenceQuery {
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

        func matches(_ item: RollingPanelPreference) -> Bool {
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

        func apply(_ items: [RollingPanelPreference]) -> [RollingPanelPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingPanelPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingPanelPreferences(_ store: any RollingPanelPreferenceStore, query: RollingPanelPreferenceQuery) -> [RollingPanelPreference] {
        return query.apply(store.list())
    }
}
