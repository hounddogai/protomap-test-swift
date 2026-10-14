import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps scheduled closure requests by code.
    protocol ScheduledClosureRequestStore {
        func find(_ code: String) -> ScheduledClosureRequest?
        func save(_ item: ScheduledClosureRequest)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledClosureRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledClosureRequestStore: ScheduledClosureRequestStore {
        var items: [String: ScheduledClosureRequest]
        var order: [String]

        init(items: [String: ScheduledClosureRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledClosureRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledClosureRequest) {
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

        func list() -> [ScheduledClosureRequest] {
            var out: [ScheduledClosureRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledClosureRequestStore() -> any ScheduledClosureRequestStore {
        return MemoryScheduledClosureRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledClosureRequestStore: ScheduledClosureRequestStore {
        var inner: MemoryScheduledClosureRequestStore
        var cache: TTLCache<ScheduledClosureRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledClosureRequestStore, cache: TTLCache<ScheduledClosureRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledClosureRequest? {
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

        func save(_ item: ScheduledClosureRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledClosureRequest] {
            return inner.list()
        }
    }

    static func newCachedScheduledClosureRequestStore(_ inner: MemoryScheduledClosureRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledClosureRequestStore {
        return CachedScheduledClosureRequestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled closure requests. Empty fields match all.
    final class ScheduledClosureRequestQuery {
        var country: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledClosureRequest) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledClosureRequest]) -> [ScheduledClosureRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledClosureRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledClosureRequests(_ store: any ScheduledClosureRequestStore, query: ScheduledClosureRequestQuery) -> [ScheduledClosureRequest] {
        return query.apply(store.list())
    }
}
