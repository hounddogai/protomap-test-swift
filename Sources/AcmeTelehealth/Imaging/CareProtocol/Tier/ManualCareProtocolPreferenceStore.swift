import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps manual care protocol preferences by code.
    protocol ManualCareProtocolPreferenceStore {
        func find(_ code: String) -> ManualCareProtocolPreference?
        func save(_ item: ManualCareProtocolPreference)
        func remove(_ code: String) -> Bool
        func list() -> [ManualCareProtocolPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualCareProtocolPreferenceStore: ManualCareProtocolPreferenceStore {
        var items: [String: ManualCareProtocolPreference]
        var order: [String]

        init(items: [String: ManualCareProtocolPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualCareProtocolPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualCareProtocolPreference) {
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

        func list() -> [ManualCareProtocolPreference] {
            var out: [ManualCareProtocolPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualCareProtocolPreferenceStore() -> any ManualCareProtocolPreferenceStore {
        return MemoryManualCareProtocolPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualCareProtocolPreferenceStore: ManualCareProtocolPreferenceStore {
        var inner: MemoryManualCareProtocolPreferenceStore
        var cache: TTLCache<ManualCareProtocolPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualCareProtocolPreferenceStore, cache: TTLCache<ManualCareProtocolPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualCareProtocolPreference? {
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

        func save(_ item: ManualCareProtocolPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualCareProtocolPreference] {
            return inner.list()
        }
    }

    static func newCachedManualCareProtocolPreferenceStore(_ inner: MemoryManualCareProtocolPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualCareProtocolPreferenceStore {
        return CachedManualCareProtocolPreferenceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual care protocol preferences. Empty fields match all.
    final class ManualCareProtocolPreferenceQuery {
        var label: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMargin: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualCareProtocolPreference) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualCareProtocolPreference]) -> [ManualCareProtocolPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualCareProtocolPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualCareProtocolPreferences(_ store: any ManualCareProtocolPreferenceStore, query: ManualCareProtocolPreferenceQuery) -> [ManualCareProtocolPreference] {
        return query.apply(store.list())
    }
}
