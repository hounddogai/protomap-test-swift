import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach preferences by code.
    protocol OutreachPreferenceStore {
        func find(_ code: String) -> OutreachPreference?
        func save(_ item: OutreachPreference)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachPreferenceStore: OutreachPreferenceStore {
        var items: [String: OutreachPreference]
        var order: [String]

        init(items: [String: OutreachPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachPreference) {
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

        func list() -> [OutreachPreference] {
            var out: [OutreachPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachPreferenceStore() -> any OutreachPreferenceStore {
        return MemoryOutreachPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachPreferenceStore: OutreachPreferenceStore {
        var inner: MemoryOutreachPreferenceStore
        var cache: TTLCache<OutreachPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachPreferenceStore, cache: TTLCache<OutreachPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachPreference? {
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

        func save(_ item: OutreachPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachPreference] {
            return inner.list()
        }
    }

    static func newCachedOutreachPreferenceStore(_ inner: MemoryOutreachPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachPreferenceStore {
        return CachedOutreachPreferenceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach preferences. Empty fields match all.
    final class OutreachPreferenceQuery {
        var category: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minLimit: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachPreference) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OutreachPreference]) -> [OutreachPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachPreferences(_ store: any OutreachPreferenceStore, query: OutreachPreferenceQuery) -> [OutreachPreference] {
        return query.apply(store.list())
    }
}
