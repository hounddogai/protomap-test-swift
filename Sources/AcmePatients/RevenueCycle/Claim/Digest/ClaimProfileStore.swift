import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim profiles by code.
    protocol ClaimProfileStore {
        func find(_ code: String) -> ClaimProfile?
        func save(_ item: ClaimProfile)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimProfileStore: ClaimProfileStore {
        var items: [String: ClaimProfile]
        var order: [String]

        init(items: [String: ClaimProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimProfile) {
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

        func list() -> [ClaimProfile] {
            var out: [ClaimProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimProfileStore() -> any ClaimProfileStore {
        return MemoryClaimProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimProfileStore: ClaimProfileStore {
        var inner: MemoryClaimProfileStore
        var cache: TTLCache<ClaimProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimProfileStore, cache: TTLCache<ClaimProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimProfile? {
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

        func save(_ item: ClaimProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimProfile] {
            return inner.list()
        }
    }

    static func newCachedClaimProfileStore(_ inner: MemoryClaimProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimProfileStore {
        return CachedClaimProfileStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim profiles. Empty fields match all.
    final class ClaimProfileQuery {
        var segment: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimProfile) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClaimProfile]) -> [ClaimProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimProfiles(_ store: any ClaimProfileStore, query: ClaimProfileQuery) -> [ClaimProfile] {
        return query.apply(store.list())
    }
}
