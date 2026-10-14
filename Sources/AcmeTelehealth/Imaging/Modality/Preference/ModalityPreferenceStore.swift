import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality preferences by code.
    protocol ModalityPreferenceStore {
        func find(_ code: String) -> ModalityPreference?
        func save(_ item: ModalityPreference)
        func remove(_ code: String) -> Bool
        func list() -> [ModalityPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalityPreferenceStore: ModalityPreferenceStore {
        var items: [String: ModalityPreference]
        var order: [String]

        init(items: [String: ModalityPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalityPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalityPreference) {
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

        func list() -> [ModalityPreference] {
            var out: [ModalityPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalityPreferenceStore() -> any ModalityPreferenceStore {
        return MemoryModalityPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalityPreferenceStore: ModalityPreferenceStore {
        var inner: MemoryModalityPreferenceStore
        var cache: TTLCache<ModalityPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalityPreferenceStore, cache: TTLCache<ModalityPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalityPreference? {
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

        func save(_ item: ModalityPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalityPreference] {
            return inner.list()
        }
    }

    static func newCachedModalityPreferenceStore(_ inner: MemoryModalityPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalityPreferenceStore {
        return CachedModalityPreferenceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality preferences. Empty fields match all.
    final class ModalityPreferenceQuery {
        var title: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ModalityPreference) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ModalityPreference]) -> [ModalityPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalityPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalityPreferences(_ store: any ModalityPreferenceStore, query: ModalityPreferenceQuery) -> [ModalityPreference] {
        return query.apply(store.list())
    }
}
