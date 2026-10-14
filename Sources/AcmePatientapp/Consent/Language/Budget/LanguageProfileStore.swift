import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language profiles by code.
    protocol LanguageProfileStore {
        func find(_ code: String) -> LanguageProfile?
        func save(_ item: LanguageProfile)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageProfileStore: LanguageProfileStore {
        var items: [String: LanguageProfile]
        var order: [String]

        init(items: [String: LanguageProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageProfile) {
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

        func list() -> [LanguageProfile] {
            var out: [LanguageProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageProfileStore() -> any LanguageProfileStore {
        return MemoryLanguageProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageProfileStore: LanguageProfileStore {
        var inner: MemoryLanguageProfileStore
        var cache: TTLCache<LanguageProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageProfileStore, cache: TTLCache<LanguageProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageProfile? {
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

        func save(_ item: LanguageProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageProfile] {
            return inner.list()
        }
    }

    static func newCachedLanguageProfileStore(_ inner: MemoryLanguageProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageProfileStore {
        return CachedLanguageProfileStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language profiles. Empty fields match all.
    final class LanguageProfileQuery {
        var name: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageProfile) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [LanguageProfile]) -> [LanguageProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageProfiles(_ store: any LanguageProfileStore, query: LanguageProfileQuery) -> [LanguageProfile] {
        return query.apply(store.list())
    }
}
