import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up groups by code.
    protocol FollowUpGroupStore {
        func find(_ code: String) -> FollowUpGroup?
        func save(_ item: FollowUpGroup)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpGroupStore: FollowUpGroupStore {
        var items: [String: FollowUpGroup]
        var order: [String]

        init(items: [String: FollowUpGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpGroup) {
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

        func list() -> [FollowUpGroup] {
            var out: [FollowUpGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpGroupStore() -> any FollowUpGroupStore {
        return MemoryFollowUpGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpGroupStore: FollowUpGroupStore {
        var inner: MemoryFollowUpGroupStore
        var cache: TTLCache<FollowUpGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpGroupStore, cache: TTLCache<FollowUpGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpGroup? {
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

        func save(_ item: FollowUpGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpGroup] {
            return inner.list()
        }
    }

    static func newCachedFollowUpGroupStore(_ inner: MemoryFollowUpGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpGroupStore {
        return CachedFollowUpGroupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up groups. Empty fields match all.
    final class FollowUpGroupQuery {
        var ward: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpGroup) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpGroup]) -> [FollowUpGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpGroups(_ store: any FollowUpGroupStore, query: FollowUpGroupQuery) -> [FollowUpGroup] {
        return query.apply(store.list())
    }
}
