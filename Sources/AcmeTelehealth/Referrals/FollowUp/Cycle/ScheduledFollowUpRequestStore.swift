import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps scheduled follow up requests by code.
    protocol ScheduledFollowUpRequestStore {
        func find(_ code: String) -> ScheduledFollowUpRequest?
        func save(_ item: ScheduledFollowUpRequest)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledFollowUpRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledFollowUpRequestStore: ScheduledFollowUpRequestStore {
        var items: [String: ScheduledFollowUpRequest]
        var order: [String]

        init(items: [String: ScheduledFollowUpRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledFollowUpRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledFollowUpRequest) {
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

        func list() -> [ScheduledFollowUpRequest] {
            var out: [ScheduledFollowUpRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledFollowUpRequestStore() -> any ScheduledFollowUpRequestStore {
        return MemoryScheduledFollowUpRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledFollowUpRequestStore: ScheduledFollowUpRequestStore {
        var inner: MemoryScheduledFollowUpRequestStore
        var cache: TTLCache<ScheduledFollowUpRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledFollowUpRequestStore, cache: TTLCache<ScheduledFollowUpRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledFollowUpRequest? {
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

        func save(_ item: ScheduledFollowUpRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledFollowUpRequest] {
            return inner.list()
        }
    }

    static func newCachedScheduledFollowUpRequestStore(_ inner: MemoryScheduledFollowUpRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledFollowUpRequestStore {
        return CachedScheduledFollowUpRequestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled follow up requests. Empty fields match all.
    final class ScheduledFollowUpRequestQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledFollowUpRequest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledFollowUpRequest]) -> [ScheduledFollowUpRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledFollowUpRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledFollowUpRequests(_ store: any ScheduledFollowUpRequestStore, query: ScheduledFollowUpRequestQuery) -> [ScheduledFollowUpRequest] {
        return query.apply(store.list())
    }
}
