import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment preferences by code.
    protocol AssessmentPreferenceStore {
        func find(_ code: String) -> AssessmentPreference?
        func save(_ item: AssessmentPreference)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentPreferenceStore: AssessmentPreferenceStore {
        var items: [String: AssessmentPreference]
        var order: [String]

        init(items: [String: AssessmentPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentPreference) {
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

        func list() -> [AssessmentPreference] {
            var out: [AssessmentPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentPreferenceStore() -> any AssessmentPreferenceStore {
        return MemoryAssessmentPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentPreferenceStore: AssessmentPreferenceStore {
        var inner: MemoryAssessmentPreferenceStore
        var cache: TTLCache<AssessmentPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentPreferenceStore, cache: TTLCache<AssessmentPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentPreference? {
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

        func save(_ item: AssessmentPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentPreference] {
            return inner.list()
        }
    }

    static func newCachedAssessmentPreferenceStore(_ inner: MemoryAssessmentPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentPreferenceStore {
        return CachedAssessmentPreferenceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment preferences. Empty fields match all.
    final class AssessmentPreferenceQuery {
        var channel: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minRefills: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentPreference) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [AssessmentPreference]) -> [AssessmentPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentPreferences(_ store: any AssessmentPreferenceStore, query: AssessmentPreferenceQuery) -> [AssessmentPreference] {
        return query.apply(store.list())
    }
}
