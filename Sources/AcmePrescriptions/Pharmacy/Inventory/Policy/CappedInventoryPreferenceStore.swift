import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps capped inventory preferences by code.
    protocol CappedInventoryPreferenceStore {
        func find(_ code: String) -> CappedInventoryPreference?
        func save(_ item: CappedInventoryPreference)
        func remove(_ code: String) -> Bool
        func list() -> [CappedInventoryPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedInventoryPreferenceStore: CappedInventoryPreferenceStore {
        var items: [String: CappedInventoryPreference]
        var order: [String]

        init(items: [String: CappedInventoryPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedInventoryPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedInventoryPreference) {
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

        func list() -> [CappedInventoryPreference] {
            var out: [CappedInventoryPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedInventoryPreferenceStore() -> any CappedInventoryPreferenceStore {
        return MemoryCappedInventoryPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedInventoryPreferenceStore: CappedInventoryPreferenceStore {
        var inner: MemoryCappedInventoryPreferenceStore
        var cache: TTLCache<CappedInventoryPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedInventoryPreferenceStore, cache: TTLCache<CappedInventoryPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedInventoryPreference? {
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

        func save(_ item: CappedInventoryPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedInventoryPreference] {
            return inner.list()
        }
    }

    static func newCachedCappedInventoryPreferenceStore(_ inner: MemoryCappedInventoryPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedInventoryPreferenceStore {
        return CachedCappedInventoryPreferenceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped inventory preferences. Empty fields match all.
    final class CappedInventoryPreferenceQuery {
        var name: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedInventoryPreference) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedInventoryPreference]) -> [CappedInventoryPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedInventoryPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedInventoryPreferences(_ store: any CappedInventoryPreferenceStore, query: CappedInventoryPreferenceQuery) -> [CappedInventoryPreference] {
        return query.apply(store.list())
    }
}
