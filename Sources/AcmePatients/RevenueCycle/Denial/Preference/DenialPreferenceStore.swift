import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial preferences by code.
    protocol DenialPreferenceStore {
        func find(_ code: String) -> DenialPreference?
        func save(_ item: DenialPreference)
        func remove(_ code: String) -> Bool
        func list() -> [DenialPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialPreferenceStore: DenialPreferenceStore {
        var items: [String: DenialPreference]
        var order: [String]

        init(items: [String: DenialPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialPreference) {
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

        func list() -> [DenialPreference] {
            var out: [DenialPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialPreferenceStore() -> any DenialPreferenceStore {
        return MemoryDenialPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialPreferenceStore: DenialPreferenceStore {
        var inner: MemoryDenialPreferenceStore
        var cache: TTLCache<DenialPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialPreferenceStore, cache: TTLCache<DenialPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialPreference? {
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

        func save(_ item: DenialPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialPreference] {
            return inner.list()
        }
    }

    static func newCachedDenialPreferenceStore(_ inner: MemoryDenialPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialPreferenceStore {
        return CachedDenialPreferenceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial preferences. Empty fields match all.
    final class DenialPreferenceQuery {
        var segment: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialPreference) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DenialPreference]) -> [DenialPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialPreferences(_ store: any DenialPreferenceStore, query: DenialPreferenceQuery) -> [DenialPreference] {
        return query.apply(store.list())
    }
}
