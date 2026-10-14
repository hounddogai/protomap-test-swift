import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps scheduled care protocol exceptions by code.
    protocol ScheduledCareProtocolExceptionStore {
        func find(_ code: String) -> ScheduledCareProtocolException?
        func save(_ item: ScheduledCareProtocolException)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledCareProtocolException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledCareProtocolExceptionStore: ScheduledCareProtocolExceptionStore {
        var items: [String: ScheduledCareProtocolException]
        var order: [String]

        init(items: [String: ScheduledCareProtocolException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledCareProtocolException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledCareProtocolException) {
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

        func list() -> [ScheduledCareProtocolException] {
            var out: [ScheduledCareProtocolException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledCareProtocolExceptionStore() -> any ScheduledCareProtocolExceptionStore {
        return MemoryScheduledCareProtocolExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledCareProtocolExceptionStore: ScheduledCareProtocolExceptionStore {
        var inner: MemoryScheduledCareProtocolExceptionStore
        var cache: TTLCache<ScheduledCareProtocolException>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledCareProtocolExceptionStore, cache: TTLCache<ScheduledCareProtocolException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledCareProtocolException? {
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

        func save(_ item: ScheduledCareProtocolException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledCareProtocolException] {
            return inner.list()
        }
    }

    static func newCachedScheduledCareProtocolExceptionStore(_ inner: MemoryScheduledCareProtocolExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledCareProtocolExceptionStore {
        return CachedScheduledCareProtocolExceptionStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled care protocol exceptions. Empty fields match all.
    final class ScheduledCareProtocolExceptionQuery {
        var region: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minPriority: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledCareProtocolException) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledCareProtocolException]) -> [ScheduledCareProtocolException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledCareProtocolException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledCareProtocolExceptions(_ store: any ScheduledCareProtocolExceptionStore, query: ScheduledCareProtocolExceptionQuery) -> [ScheduledCareProtocolException] {
        return query.apply(store.list())
    }
}
