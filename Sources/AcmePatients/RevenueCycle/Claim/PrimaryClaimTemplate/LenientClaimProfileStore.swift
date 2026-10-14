import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps lenient claim profiles by code.
    protocol LenientClaimProfileStore {
        func find(_ code: String) -> LenientClaimProfile?
        func save(_ item: LenientClaimProfile)
        func remove(_ code: String) -> Bool
        func list() -> [LenientClaimProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientClaimProfileStore: LenientClaimProfileStore {
        var items: [String: LenientClaimProfile]
        var order: [String]

        init(items: [String: LenientClaimProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientClaimProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientClaimProfile) {
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

        func list() -> [LenientClaimProfile] {
            var out: [LenientClaimProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientClaimProfileStore() -> any LenientClaimProfileStore {
        return MemoryLenientClaimProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientClaimProfileStore: LenientClaimProfileStore {
        var inner: MemoryLenientClaimProfileStore
        var cache: TTLCache<LenientClaimProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientClaimProfileStore, cache: TTLCache<LenientClaimProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientClaimProfile? {
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

        func save(_ item: LenientClaimProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientClaimProfile] {
            return inner.list()
        }
    }

    static func newCachedLenientClaimProfileStore(_ inner: MemoryLenientClaimProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientClaimProfileStore {
        return CachedLenientClaimProfileStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient claim profiles. Empty fields match all.
    final class LenientClaimProfileQuery {
        var title: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minLimit: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientClaimProfile) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientClaimProfile]) -> [LenientClaimProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientClaimProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientClaimProfiles(_ store: any LenientClaimProfileStore, query: LenientClaimProfileQuery) -> [LenientClaimProfile] {
        return query.apply(store.list())
    }
}
