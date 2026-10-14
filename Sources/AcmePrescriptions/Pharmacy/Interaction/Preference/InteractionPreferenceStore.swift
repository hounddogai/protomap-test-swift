import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction preferences by code.
    protocol InteractionPreferenceStore {
        func find(_ code: String) -> InteractionPreference?
        func save(_ item: InteractionPreference)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionPreferenceStore: InteractionPreferenceStore {
        var items: [String: InteractionPreference]
        var order: [String]

        init(items: [String: InteractionPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionPreference) {
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

        func list() -> [InteractionPreference] {
            var out: [InteractionPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionPreferenceStore() -> any InteractionPreferenceStore {
        return MemoryInteractionPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionPreferenceStore: InteractionPreferenceStore {
        var inner: MemoryInteractionPreferenceStore
        var cache: TTLCache<InteractionPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionPreferenceStore, cache: TTLCache<InteractionPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionPreference? {
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

        func save(_ item: InteractionPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionPreference] {
            return inner.list()
        }
    }

    static func newCachedInteractionPreferenceStore(_ inner: MemoryInteractionPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionPreferenceStore {
        return CachedInteractionPreferenceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction preferences. Empty fields match all.
    final class InteractionPreferenceQuery {
        var region: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minVersion: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionPreference) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionPreference]) -> [InteractionPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionPreferences(_ store: any InteractionPreferenceStore, query: InteractionPreferenceQuery) -> [InteractionPreference] {
        return query.apply(store.list())
    }
}
