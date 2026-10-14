import AcmePlatform
import Foundation

extension Labs {
    /// Keeps pending result preferences by code.
    protocol PendingResultPreferenceStore {
        func find(_ code: String) -> PendingResultPreference?
        func save(_ item: PendingResultPreference)
        func remove(_ code: String) -> Bool
        func list() -> [PendingResultPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingResultPreferenceStore: PendingResultPreferenceStore {
        var items: [String: PendingResultPreference]
        var order: [String]

        init(items: [String: PendingResultPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingResultPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingResultPreference) {
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

        func list() -> [PendingResultPreference] {
            var out: [PendingResultPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingResultPreferenceStore() -> any PendingResultPreferenceStore {
        return MemoryPendingResultPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingResultPreferenceStore: PendingResultPreferenceStore {
        var inner: MemoryPendingResultPreferenceStore
        var cache: TTLCache<PendingResultPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingResultPreferenceStore, cache: TTLCache<PendingResultPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingResultPreference? {
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

        func save(_ item: PendingResultPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingResultPreference] {
            return inner.list()
        }
    }

    static func newCachedPendingResultPreferenceStore(_ inner: MemoryPendingResultPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingResultPreferenceStore {
        return CachedPendingResultPreferenceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending result preferences. Empty fields match all.
    final class PendingResultPreferenceQuery {
        var ward: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingResultPreference) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingResultPreference]) -> [PendingResultPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingResultPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingResultPreferences(_ store: any PendingResultPreferenceStore, query: PendingResultPreferenceQuery) -> [PendingResultPreference] {
        return query.apply(store.list())
    }
}
