import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps pending cleaning preferences by code.
    protocol PendingCleaningPreferenceStore {
        func find(_ code: String) -> PendingCleaningPreference?
        func save(_ item: PendingCleaningPreference)
        func remove(_ code: String) -> Bool
        func list() -> [PendingCleaningPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingCleaningPreferenceStore: PendingCleaningPreferenceStore {
        var items: [String: PendingCleaningPreference]
        var order: [String]

        init(items: [String: PendingCleaningPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingCleaningPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingCleaningPreference) {
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

        func list() -> [PendingCleaningPreference] {
            var out: [PendingCleaningPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingCleaningPreferenceStore() -> any PendingCleaningPreferenceStore {
        return MemoryPendingCleaningPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingCleaningPreferenceStore: PendingCleaningPreferenceStore {
        var inner: MemoryPendingCleaningPreferenceStore
        var cache: TTLCache<PendingCleaningPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingCleaningPreferenceStore, cache: TTLCache<PendingCleaningPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingCleaningPreference? {
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

        func save(_ item: PendingCleaningPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingCleaningPreference] {
            return inner.list()
        }
    }

    static func newCachedPendingCleaningPreferenceStore(_ inner: MemoryPendingCleaningPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingCleaningPreferenceStore {
        return CachedPendingCleaningPreferenceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending cleaning preferences. Empty fields match all.
    final class PendingCleaningPreferenceQuery {
        var channel: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingCleaningPreference) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [PendingCleaningPreference]) -> [PendingCleaningPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingCleaningPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingCleaningPreferences(_ store: any PendingCleaningPreferenceStore, query: PendingCleaningPreferenceQuery) -> [PendingCleaningPreference] {
        return query.apply(store.list())
    }
}
