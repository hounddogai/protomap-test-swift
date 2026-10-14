import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert preferences by code.
    protocol AlertPreferenceStore {
        func find(_ code: String) -> AlertPreference?
        func save(_ item: AlertPreference)
        func remove(_ code: String) -> Bool
        func list() -> [AlertPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertPreferenceStore: AlertPreferenceStore {
        var items: [String: AlertPreference]
        var order: [String]

        init(items: [String: AlertPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertPreference) {
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

        func list() -> [AlertPreference] {
            var out: [AlertPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertPreferenceStore() -> any AlertPreferenceStore {
        return MemoryAlertPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertPreferenceStore: AlertPreferenceStore {
        var inner: MemoryAlertPreferenceStore
        var cache: TTLCache<AlertPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertPreferenceStore, cache: TTLCache<AlertPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertPreference? {
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

        func save(_ item: AlertPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertPreference] {
            return inner.list()
        }
    }

    static func newCachedAlertPreferenceStore(_ inner: MemoryAlertPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertPreferenceStore {
        return CachedAlertPreferenceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert preferences. Empty fields match all.
    final class AlertPreferenceQuery {
        var region: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertPreference) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AlertPreference]) -> [AlertPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertPreferences(_ store: any AlertPreferenceStore, query: AlertPreferenceQuery) -> [AlertPreference] {
        return query.apply(store.list())
    }
}
