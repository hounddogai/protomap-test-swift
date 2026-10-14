import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study preferences by code.
    protocol StudyPreferenceStore {
        func find(_ code: String) -> StudyPreference?
        func save(_ item: StudyPreference)
        func remove(_ code: String) -> Bool
        func list() -> [StudyPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyPreferenceStore: StudyPreferenceStore {
        var items: [String: StudyPreference]
        var order: [String]

        init(items: [String: StudyPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyPreference) {
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

        func list() -> [StudyPreference] {
            var out: [StudyPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyPreferenceStore() -> any StudyPreferenceStore {
        return MemoryStudyPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyPreferenceStore: StudyPreferenceStore {
        var inner: MemoryStudyPreferenceStore
        var cache: TTLCache<StudyPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyPreferenceStore, cache: TTLCache<StudyPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyPreference? {
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

        func save(_ item: StudyPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyPreference] {
            return inner.list()
        }
    }

    static func newCachedStudyPreferenceStore(_ inner: MemoryStudyPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyPreferenceStore {
        return CachedStudyPreferenceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study preferences. Empty fields match all.
    final class StudyPreferenceQuery {
        var name: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudyPreference) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StudyPreference]) -> [StudyPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyPreferences(_ store: any StudyPreferenceStore, query: StudyPreferenceQuery) -> [StudyPreference] {
        return query.apply(store.list())
    }
}
