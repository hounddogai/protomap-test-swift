import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure preferences by code.
    protocol DisclosurePreferenceStore {
        func find(_ code: String) -> DisclosurePreference?
        func save(_ item: DisclosurePreference)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosurePreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosurePreferenceStore: DisclosurePreferenceStore {
        var items: [String: DisclosurePreference]
        var order: [String]

        init(items: [String: DisclosurePreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosurePreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosurePreference) {
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

        func list() -> [DisclosurePreference] {
            var out: [DisclosurePreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosurePreferenceStore() -> any DisclosurePreferenceStore {
        return MemoryDisclosurePreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosurePreferenceStore: DisclosurePreferenceStore {
        var inner: MemoryDisclosurePreferenceStore
        var cache: TTLCache<DisclosurePreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosurePreferenceStore, cache: TTLCache<DisclosurePreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosurePreference? {
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

        func save(_ item: DisclosurePreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosurePreference] {
            return inner.list()
        }
    }

    static func newCachedDisclosurePreferenceStore(_ inner: MemoryDisclosurePreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosurePreferenceStore {
        return CachedDisclosurePreferenceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure preferences. Empty fields match all.
    final class DisclosurePreferenceQuery {
        var ward: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minAmount: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosurePreference) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DisclosurePreference]) -> [DisclosurePreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosurePreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosurePreferences(_ store: any DisclosurePreferenceStore, query: DisclosurePreferenceQuery) -> [DisclosurePreference] {
        return query.apply(store.list())
    }
}
