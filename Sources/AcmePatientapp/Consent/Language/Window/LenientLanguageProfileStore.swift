import AcmePlatform
import Foundation

extension Consent {
    /// Keeps lenient language profiles by code.
    protocol LenientLanguageProfileStore {
        func find(_ code: String) -> LenientLanguageProfile?
        func save(_ item: LenientLanguageProfile)
        func remove(_ code: String) -> Bool
        func list() -> [LenientLanguageProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientLanguageProfileStore: LenientLanguageProfileStore {
        var items: [String: LenientLanguageProfile]
        var order: [String]

        init(items: [String: LenientLanguageProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientLanguageProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientLanguageProfile) {
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

        func list() -> [LenientLanguageProfile] {
            var out: [LenientLanguageProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientLanguageProfileStore() -> any LenientLanguageProfileStore {
        return MemoryLenientLanguageProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientLanguageProfileStore: LenientLanguageProfileStore {
        var inner: MemoryLenientLanguageProfileStore
        var cache: TTLCache<LenientLanguageProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientLanguageProfileStore, cache: TTLCache<LenientLanguageProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientLanguageProfile? {
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

        func save(_ item: LenientLanguageProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientLanguageProfile] {
            return inner.list()
        }
    }

    static func newCachedLenientLanguageProfileStore(_ inner: MemoryLenientLanguageProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientLanguageProfileStore {
        return CachedLenientLanguageProfileStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient language profiles. Empty fields match all.
    final class LenientLanguageProfileQuery {
        var region: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientLanguageProfile) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientLanguageProfile]) -> [LenientLanguageProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientLanguageProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientLanguageProfiles(_ store: any LenientLanguageProfileStore, query: LenientLanguageProfileQuery) -> [LenientLanguageProfile] {
        return query.apply(store.list())
    }
}
