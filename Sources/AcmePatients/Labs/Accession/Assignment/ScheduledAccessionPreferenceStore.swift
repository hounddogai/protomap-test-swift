import AcmePlatform
import Foundation

extension Labs {
    /// Keeps scheduled accession preferences by code.
    protocol ScheduledAccessionPreferenceStore {
        func find(_ code: String) -> ScheduledAccessionPreference?
        func save(_ item: ScheduledAccessionPreference)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledAccessionPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledAccessionPreferenceStore: ScheduledAccessionPreferenceStore {
        var items: [String: ScheduledAccessionPreference]
        var order: [String]

        init(items: [String: ScheduledAccessionPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledAccessionPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledAccessionPreference) {
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

        func list() -> [ScheduledAccessionPreference] {
            var out: [ScheduledAccessionPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledAccessionPreferenceStore() -> any ScheduledAccessionPreferenceStore {
        return MemoryScheduledAccessionPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledAccessionPreferenceStore: ScheduledAccessionPreferenceStore {
        var inner: MemoryScheduledAccessionPreferenceStore
        var cache: TTLCache<ScheduledAccessionPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledAccessionPreferenceStore, cache: TTLCache<ScheduledAccessionPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledAccessionPreference? {
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

        func save(_ item: ScheduledAccessionPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledAccessionPreference] {
            return inner.list()
        }
    }

    static func newCachedScheduledAccessionPreferenceStore(_ inner: MemoryScheduledAccessionPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledAccessionPreferenceStore {
        return CachedScheduledAccessionPreferenceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled accession preferences. Empty fields match all.
    final class ScheduledAccessionPreferenceQuery {
        var channel: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minWeight: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledAccessionPreference) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledAccessionPreference]) -> [ScheduledAccessionPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledAccessionPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledAccessionPreferences(_ store: any ScheduledAccessionPreferenceStore, query: ScheduledAccessionPreferenceQuery) -> [ScheduledAccessionPreference] {
        return query.apply(store.list())
    }
}
