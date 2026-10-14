import AcmePlatform
import Foundation

extension Consent {
    /// Keeps fallback disclosure profiles by code.
    protocol FallbackDisclosureProfileStore {
        func find(_ code: String) -> FallbackDisclosureProfile?
        func save(_ item: FallbackDisclosureProfile)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackDisclosureProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackDisclosureProfileStore: FallbackDisclosureProfileStore {
        var items: [String: FallbackDisclosureProfile]
        var order: [String]

        init(items: [String: FallbackDisclosureProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackDisclosureProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackDisclosureProfile) {
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

        func list() -> [FallbackDisclosureProfile] {
            var out: [FallbackDisclosureProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackDisclosureProfileStore() -> any FallbackDisclosureProfileStore {
        return MemoryFallbackDisclosureProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackDisclosureProfileStore: FallbackDisclosureProfileStore {
        var inner: MemoryFallbackDisclosureProfileStore
        var cache: TTLCache<FallbackDisclosureProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackDisclosureProfileStore, cache: TTLCache<FallbackDisclosureProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackDisclosureProfile? {
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

        func save(_ item: FallbackDisclosureProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackDisclosureProfile] {
            return inner.list()
        }
    }

    static func newCachedFallbackDisclosureProfileStore(_ inner: MemoryFallbackDisclosureProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackDisclosureProfileStore {
        return CachedFallbackDisclosureProfileStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback disclosure profiles. Empty fields match all.
    final class FallbackDisclosureProfileQuery {
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

        func matches(_ item: FallbackDisclosureProfile) -> Bool {
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

        func apply(_ items: [FallbackDisclosureProfile]) -> [FallbackDisclosureProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackDisclosureProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackDisclosureProfiles(_ store: any FallbackDisclosureProfileStore, query: FallbackDisclosureProfileQuery) -> [FallbackDisclosureProfile] {
        return query.apply(store.list())
    }
}
