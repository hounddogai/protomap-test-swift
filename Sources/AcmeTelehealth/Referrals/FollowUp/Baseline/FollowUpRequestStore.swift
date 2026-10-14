import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up requests by code.
    protocol FollowUpRequestStore {
        func find(_ code: String) -> FollowUpRequest?
        func save(_ item: FollowUpRequest)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpRequestStore: FollowUpRequestStore {
        var items: [String: FollowUpRequest]
        var order: [String]

        init(items: [String: FollowUpRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpRequest) {
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

        func list() -> [FollowUpRequest] {
            var out: [FollowUpRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpRequestStore() -> any FollowUpRequestStore {
        return MemoryFollowUpRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpRequestStore: FollowUpRequestStore {
        var inner: MemoryFollowUpRequestStore
        var cache: TTLCache<FollowUpRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpRequestStore, cache: TTLCache<FollowUpRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpRequest? {
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

        func save(_ item: FollowUpRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpRequest] {
            return inner.list()
        }
    }

    static func newCachedFollowUpRequestStore(_ inner: MemoryFollowUpRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpRequestStore {
        return CachedFollowUpRequestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up requests. Empty fields match all.
    final class FollowUpRequestQuery {
        var title: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpRequest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [FollowUpRequest]) -> [FollowUpRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpRequests(_ store: any FollowUpRequestStore, query: FollowUpRequestQuery) -> [FollowUpRequest] {
        return query.apply(store.list())
    }
}
