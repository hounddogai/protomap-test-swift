import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program preferences by code.
    protocol ProgramPreferenceStore {
        func find(_ code: String) -> ProgramPreference?
        func save(_ item: ProgramPreference)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramPreferenceStore: ProgramPreferenceStore {
        var items: [String: ProgramPreference]
        var order: [String]

        init(items: [String: ProgramPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramPreference) {
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

        func list() -> [ProgramPreference] {
            var out: [ProgramPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramPreferenceStore() -> any ProgramPreferenceStore {
        return MemoryProgramPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramPreferenceStore: ProgramPreferenceStore {
        var inner: MemoryProgramPreferenceStore
        var cache: TTLCache<ProgramPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramPreferenceStore, cache: TTLCache<ProgramPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramPreference? {
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

        func save(_ item: ProgramPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramPreference] {
            return inner.list()
        }
    }

    static func newCachedProgramPreferenceStore(_ inner: MemoryProgramPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramPreferenceStore {
        return CachedProgramPreferenceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program preferences. Empty fields match all.
    final class ProgramPreferenceQuery {
        var title: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramPreference) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProgramPreference]) -> [ProgramPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramPreferences(_ store: any ProgramPreferenceStore, query: ProgramPreferenceQuery) -> [ProgramPreference] {
        return query.apply(store.list())
    }
}
