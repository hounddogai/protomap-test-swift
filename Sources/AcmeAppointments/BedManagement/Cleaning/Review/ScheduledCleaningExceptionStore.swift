import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps scheduled cleaning exceptions by code.
    protocol ScheduledCleaningExceptionStore {
        func find(_ code: String) -> ScheduledCleaningException?
        func save(_ item: ScheduledCleaningException)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledCleaningException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledCleaningExceptionStore: ScheduledCleaningExceptionStore {
        var items: [String: ScheduledCleaningException]
        var order: [String]

        init(items: [String: ScheduledCleaningException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledCleaningException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledCleaningException) {
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

        func list() -> [ScheduledCleaningException] {
            var out: [ScheduledCleaningException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledCleaningExceptionStore() -> any ScheduledCleaningExceptionStore {
        return MemoryScheduledCleaningExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledCleaningExceptionStore: ScheduledCleaningExceptionStore {
        var inner: MemoryScheduledCleaningExceptionStore
        var cache: TTLCache<ScheduledCleaningException>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledCleaningExceptionStore, cache: TTLCache<ScheduledCleaningException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledCleaningException? {
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

        func save(_ item: ScheduledCleaningException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledCleaningException] {
            return inner.list()
        }
    }

    static func newCachedScheduledCleaningExceptionStore(_ inner: MemoryScheduledCleaningExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledCleaningExceptionStore {
        return CachedScheduledCleaningExceptionStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled cleaning exceptions. Empty fields match all.
    final class ScheduledCleaningExceptionQuery {
        var name: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minBudget: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledCleaningException) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledCleaningException]) -> [ScheduledCleaningException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledCleaningException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledCleaningExceptions(_ store: any ScheduledCleaningExceptionStore, query: ScheduledCleaningExceptionQuery) -> [ScheduledCleaningException] {
        return query.apply(store.list())
    }
}
