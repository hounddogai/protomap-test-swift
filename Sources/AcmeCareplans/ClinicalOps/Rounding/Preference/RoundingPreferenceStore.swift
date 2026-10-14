import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding preferences by code.
    protocol RoundingPreferenceStore {
        func find(_ code: String) -> RoundingPreference?
        func save(_ item: RoundingPreference)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingPreferenceStore: RoundingPreferenceStore {
        var items: [String: RoundingPreference]
        var order: [String]

        init(items: [String: RoundingPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingPreference) {
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

        func list() -> [RoundingPreference] {
            var out: [RoundingPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingPreferenceStore() -> any RoundingPreferenceStore {
        return MemoryRoundingPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingPreferenceStore: RoundingPreferenceStore {
        var inner: MemoryRoundingPreferenceStore
        var cache: TTLCache<RoundingPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingPreferenceStore, cache: TTLCache<RoundingPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingPreference? {
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

        func save(_ item: RoundingPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingPreference] {
            return inner.list()
        }
    }

    static func newCachedRoundingPreferenceStore(_ inner: MemoryRoundingPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingPreferenceStore {
        return CachedRoundingPreferenceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding preferences. Empty fields match all.
    final class RoundingPreferenceQuery {
        var source: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minRetries: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingPreference) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingPreference]) -> [RoundingPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingPreferences(_ store: any RoundingPreferenceStore, query: RoundingPreferenceQuery) -> [RoundingPreference] {
        return query.apply(store.list())
    }
}
