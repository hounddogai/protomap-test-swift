import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up profiles by code.
    protocol FollowUpProfileStore {
        func find(_ code: String) -> FollowUpProfile?
        func save(_ item: FollowUpProfile)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpProfileStore: FollowUpProfileStore {
        var items: [String: FollowUpProfile]
        var order: [String]

        init(items: [String: FollowUpProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpProfile) {
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

        func list() -> [FollowUpProfile] {
            var out: [FollowUpProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpProfileStore() -> any FollowUpProfileStore {
        return MemoryFollowUpProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpProfileStore: FollowUpProfileStore {
        var inner: MemoryFollowUpProfileStore
        var cache: TTLCache<FollowUpProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpProfileStore, cache: TTLCache<FollowUpProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpProfile? {
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

        func save(_ item: FollowUpProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpProfile] {
            return inner.list()
        }
    }

    static func newCachedFollowUpProfileStore(_ inner: MemoryFollowUpProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpProfileStore {
        return CachedFollowUpProfileStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up profiles. Empty fields match all.
    final class FollowUpProfileQuery {
        var country: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minCopay: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpProfile) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpProfile]) -> [FollowUpProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpProfiles(_ store: any FollowUpProfileStore, query: FollowUpProfileQuery) -> [FollowUpProfile] {
        return query.apply(store.list())
    }
}
