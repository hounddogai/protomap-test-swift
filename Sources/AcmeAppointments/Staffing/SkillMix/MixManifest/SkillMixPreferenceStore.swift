import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix preferences by code.
    protocol SkillMixPreferenceStore {
        func find(_ code: String) -> SkillMixPreference?
        func save(_ item: SkillMixPreference)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixPreferenceStore: SkillMixPreferenceStore {
        var items: [String: SkillMixPreference]
        var order: [String]

        init(items: [String: SkillMixPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixPreference) {
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

        func list() -> [SkillMixPreference] {
            var out: [SkillMixPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixPreferenceStore() -> any SkillMixPreferenceStore {
        return MemorySkillMixPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixPreferenceStore: SkillMixPreferenceStore {
        var inner: MemorySkillMixPreferenceStore
        var cache: TTLCache<SkillMixPreference>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixPreferenceStore, cache: TTLCache<SkillMixPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixPreference? {
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

        func save(_ item: SkillMixPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixPreference] {
            return inner.list()
        }
    }

    static func newCachedSkillMixPreferenceStore(_ inner: MemorySkillMixPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixPreferenceStore {
        return CachedSkillMixPreferenceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix preferences. Empty fields match all.
    final class SkillMixPreferenceQuery {
        var locale: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixPreference) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixPreference]) -> [SkillMixPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixPreferences(_ store: any SkillMixPreferenceStore, query: SkillMixPreferenceQuery) -> [SkillMixPreference] {
        return query.apply(store.list())
    }
}
