import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result preferences by code.
    protocol ResultPreferenceStore {
        func find(_ code: String) -> ResultPreference?
        func save(_ item: ResultPreference)
        func remove(_ code: String) -> Bool
        func list() -> [ResultPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultPreferenceStore: ResultPreferenceStore {
        var items: [String: ResultPreference]
        var order: [String]

        init(items: [String: ResultPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultPreference) {
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

        func list() -> [ResultPreference] {
            var out: [ResultPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultPreferenceStore() -> any ResultPreferenceStore {
        return MemoryResultPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultPreferenceStore: ResultPreferenceStore {
        var inner: MemoryResultPreferenceStore
        var cache: TTLCache<ResultPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultPreferenceStore, cache: TTLCache<ResultPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultPreference? {
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

        func save(_ item: ResultPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultPreference] {
            return inner.list()
        }
    }

    static func newCachedResultPreferenceStore(_ inner: MemoryResultPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultPreferenceStore {
        return CachedResultPreferenceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result preferences. Empty fields match all.
    final class ResultPreferenceQuery {
        var channel: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minVersion: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultPreference) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [ResultPreference]) -> [ResultPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultPreferences(_ store: any ResultPreferenceStore, query: ResultPreferenceQuery) -> [ResultPreference] {
        return query.apply(store.list())
    }
}
