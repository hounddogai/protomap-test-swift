import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime preferences by code.
    protocol OvertimePreferenceStore {
        func find(_ code: String) -> OvertimePreference?
        func save(_ item: OvertimePreference)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimePreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimePreferenceStore: OvertimePreferenceStore {
        var items: [String: OvertimePreference]
        var order: [String]

        init(items: [String: OvertimePreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimePreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimePreference) {
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

        func list() -> [OvertimePreference] {
            var out: [OvertimePreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimePreferenceStore() -> any OvertimePreferenceStore {
        return MemoryOvertimePreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimePreferenceStore: OvertimePreferenceStore {
        var inner: MemoryOvertimePreferenceStore
        var cache: TTLCache<OvertimePreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimePreferenceStore, cache: TTLCache<OvertimePreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimePreference? {
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

        func save(_ item: OvertimePreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimePreference] {
            return inner.list()
        }
    }

    static func newCachedOvertimePreferenceStore(_ inner: MemoryOvertimePreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimePreferenceStore {
        return CachedOvertimePreferenceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime preferences. Empty fields match all.
    final class OvertimePreferenceQuery {
        var title: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimePreference) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OvertimePreference]) -> [OvertimePreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimePreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimePreferences(_ store: any OvertimePreferenceStore, query: OvertimePreferenceQuery) -> [OvertimePreference] {
        return query.apply(store.list())
    }
}
