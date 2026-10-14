import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps lenient isolation preferences by code.
    protocol LenientIsolationPreferenceStore {
        func find(_ code: String) -> LenientIsolationPreference?
        func save(_ item: LenientIsolationPreference)
        func remove(_ code: String) -> Bool
        func list() -> [LenientIsolationPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientIsolationPreferenceStore: LenientIsolationPreferenceStore {
        var items: [String: LenientIsolationPreference]
        var order: [String]

        init(items: [String: LenientIsolationPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientIsolationPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientIsolationPreference) {
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

        func list() -> [LenientIsolationPreference] {
            var out: [LenientIsolationPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientIsolationPreferenceStore() -> any LenientIsolationPreferenceStore {
        return MemoryLenientIsolationPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientIsolationPreferenceStore: LenientIsolationPreferenceStore {
        var inner: MemoryLenientIsolationPreferenceStore
        var cache: TTLCache<LenientIsolationPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientIsolationPreferenceStore, cache: TTLCache<LenientIsolationPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientIsolationPreference? {
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

        func save(_ item: LenientIsolationPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientIsolationPreference] {
            return inner.list()
        }
    }

    static func newCachedLenientIsolationPreferenceStore(_ inner: MemoryLenientIsolationPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientIsolationPreferenceStore {
        return CachedLenientIsolationPreferenceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient isolation preferences. Empty fields match all.
    final class LenientIsolationPreferenceQuery {
        var title: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minPriority: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientIsolationPreference) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientIsolationPreference]) -> [LenientIsolationPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientIsolationPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientIsolationPreferences(_ store: any LenientIsolationPreferenceStore, query: LenientIsolationPreferenceQuery) -> [LenientIsolationPreference] {
        return query.apply(store.list())
    }
}
