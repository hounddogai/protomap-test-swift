import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps scheduled outreach requests by code.
    protocol ScheduledOutreachRequestStore {
        func find(_ code: String) -> ScheduledOutreachRequest?
        func save(_ item: ScheduledOutreachRequest)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledOutreachRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledOutreachRequestStore: ScheduledOutreachRequestStore {
        var items: [String: ScheduledOutreachRequest]
        var order: [String]

        init(items: [String: ScheduledOutreachRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledOutreachRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledOutreachRequest) {
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

        func list() -> [ScheduledOutreachRequest] {
            var out: [ScheduledOutreachRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledOutreachRequestStore() -> any ScheduledOutreachRequestStore {
        return MemoryScheduledOutreachRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledOutreachRequestStore: ScheduledOutreachRequestStore {
        var inner: MemoryScheduledOutreachRequestStore
        var cache: TTLCache<ScheduledOutreachRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledOutreachRequestStore, cache: TTLCache<ScheduledOutreachRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledOutreachRequest? {
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

        func save(_ item: ScheduledOutreachRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledOutreachRequest] {
            return inner.list()
        }
    }

    static func newCachedScheduledOutreachRequestStore(_ inner: MemoryScheduledOutreachRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledOutreachRequestStore {
        return CachedScheduledOutreachRequestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled outreach requests. Empty fields match all.
    final class ScheduledOutreachRequestQuery {
        var locale: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minAmount: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledOutreachRequest) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledOutreachRequest]) -> [ScheduledOutreachRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledOutreachRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledOutreachRequests(_ store: any ScheduledOutreachRequestStore, query: ScheduledOutreachRequestQuery) -> [ScheduledOutreachRequest] {
        return query.apply(store.list())
    }
}
