import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory preferences by code.
    protocol InventoryPreferenceStore {
        func find(_ code: String) -> InventoryPreference?
        func save(_ item: InventoryPreference)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryPreferenceStore: InventoryPreferenceStore {
        var items: [String: InventoryPreference]
        var order: [String]

        init(items: [String: InventoryPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryPreference) {
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

        func list() -> [InventoryPreference] {
            var out: [InventoryPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryPreferenceStore() -> any InventoryPreferenceStore {
        return MemoryInventoryPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryPreferenceStore: InventoryPreferenceStore {
        var inner: MemoryInventoryPreferenceStore
        var cache: TTLCache<InventoryPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryPreferenceStore, cache: TTLCache<InventoryPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryPreference? {
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

        func save(_ item: InventoryPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryPreference] {
            return inner.list()
        }
    }

    static func newCachedInventoryPreferenceStore(_ inner: MemoryInventoryPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryPreferenceStore {
        return CachedInventoryPreferenceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory preferences. Empty fields match all.
    final class InventoryPreferenceQuery {
        var channel: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventoryPreference) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InventoryPreference]) -> [InventoryPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryPreferences(_ store: any InventoryPreferenceStore, query: InventoryPreferenceQuery) -> [InventoryPreference] {
        return query.apply(store.list())
    }
}
