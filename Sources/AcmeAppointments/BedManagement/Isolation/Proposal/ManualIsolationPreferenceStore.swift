import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps manual isolation preferences by code.
    protocol ManualIsolationPreferenceStore {
        func find(_ code: String) -> ManualIsolationPreference?
        func save(_ item: ManualIsolationPreference)
        func remove(_ code: String) -> Bool
        func list() -> [ManualIsolationPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualIsolationPreferenceStore: ManualIsolationPreferenceStore {
        var items: [String: ManualIsolationPreference]
        var order: [String]

        init(items: [String: ManualIsolationPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualIsolationPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualIsolationPreference) {
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

        func list() -> [ManualIsolationPreference] {
            var out: [ManualIsolationPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualIsolationPreferenceStore() -> any ManualIsolationPreferenceStore {
        return MemoryManualIsolationPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualIsolationPreferenceStore: ManualIsolationPreferenceStore {
        var inner: MemoryManualIsolationPreferenceStore
        var cache: TTLCache<ManualIsolationPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualIsolationPreferenceStore, cache: TTLCache<ManualIsolationPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualIsolationPreference? {
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

        func save(_ item: ManualIsolationPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualIsolationPreference] {
            return inner.list()
        }
    }

    static func newCachedManualIsolationPreferenceStore(_ inner: MemoryManualIsolationPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualIsolationPreferenceStore {
        return CachedManualIsolationPreferenceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual isolation preferences. Empty fields match all.
    final class ManualIsolationPreferenceQuery {
        var country: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minScore: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualIsolationPreference) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualIsolationPreference]) -> [ManualIsolationPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualIsolationPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualIsolationPreferences(_ store: any ManualIsolationPreferenceStore, query: ManualIsolationPreferenceQuery) -> [ManualIsolationPreference] {
        return query.apply(store.list())
    }
}
