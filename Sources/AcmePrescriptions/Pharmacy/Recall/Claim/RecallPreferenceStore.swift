import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall preferences by code.
    protocol RecallPreferenceStore {
        func find(_ code: String) -> RecallPreference?
        func save(_ item: RecallPreference)
        func remove(_ code: String) -> Bool
        func list() -> [RecallPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallPreferenceStore: RecallPreferenceStore {
        var items: [String: RecallPreference]
        var order: [String]

        init(items: [String: RecallPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallPreference) {
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

        func list() -> [RecallPreference] {
            var out: [RecallPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallPreferenceStore() -> any RecallPreferenceStore {
        return MemoryRecallPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallPreferenceStore: RecallPreferenceStore {
        var inner: MemoryRecallPreferenceStore
        var cache: TTLCache<RecallPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallPreferenceStore, cache: TTLCache<RecallPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallPreference? {
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

        func save(_ item: RecallPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallPreference] {
            return inner.list()
        }
    }

    static func newCachedRecallPreferenceStore(_ inner: MemoryRecallPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallPreferenceStore {
        return CachedRecallPreferenceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall preferences. Empty fields match all.
    final class RecallPreferenceQuery {
        var label: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRefills: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallPreference) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RecallPreference]) -> [RecallPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallPreferences(_ store: any RecallPreferenceStore, query: RecallPreferenceQuery) -> [RecallPreference] {
        return query.apply(store.list())
    }
}
