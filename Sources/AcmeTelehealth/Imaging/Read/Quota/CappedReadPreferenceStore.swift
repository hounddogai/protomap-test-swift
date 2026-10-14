import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps capped read preferences by code.
    protocol CappedReadPreferenceStore {
        func find(_ code: String) -> CappedReadPreference?
        func save(_ item: CappedReadPreference)
        func remove(_ code: String) -> Bool
        func list() -> [CappedReadPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedReadPreferenceStore: CappedReadPreferenceStore {
        var items: [String: CappedReadPreference]
        var order: [String]

        init(items: [String: CappedReadPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedReadPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedReadPreference) {
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

        func list() -> [CappedReadPreference] {
            var out: [CappedReadPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedReadPreferenceStore() -> any CappedReadPreferenceStore {
        return MemoryCappedReadPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedReadPreferenceStore: CappedReadPreferenceStore {
        var inner: MemoryCappedReadPreferenceStore
        var cache: TTLCache<CappedReadPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedReadPreferenceStore, cache: TTLCache<CappedReadPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedReadPreference? {
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

        func save(_ item: CappedReadPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedReadPreference] {
            return inner.list()
        }
    }

    static func newCachedCappedReadPreferenceStore(_ inner: MemoryCappedReadPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedReadPreferenceStore {
        return CachedCappedReadPreferenceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped read preferences. Empty fields match all.
    final class CappedReadPreferenceQuery {
        var title: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minLimit: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedReadPreference) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [CappedReadPreference]) -> [CappedReadPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedReadPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedReadPreferences(_ store: any CappedReadPreferenceStore, query: CappedReadPreferenceQuery) -> [CappedReadPreference] {
        return query.apply(store.list())
    }
}
