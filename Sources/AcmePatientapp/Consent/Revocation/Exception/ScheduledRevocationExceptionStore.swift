import AcmePlatform
import Foundation

extension Consent {
    /// Keeps scheduled revocation exceptions by code.
    protocol ScheduledRevocationExceptionStore {
        func find(_ code: String) -> ScheduledRevocationException?
        func save(_ item: ScheduledRevocationException)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledRevocationException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledRevocationExceptionStore: ScheduledRevocationExceptionStore {
        var items: [String: ScheduledRevocationException]
        var order: [String]

        init(items: [String: ScheduledRevocationException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledRevocationException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledRevocationException) {
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

        func list() -> [ScheduledRevocationException] {
            var out: [ScheduledRevocationException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledRevocationExceptionStore() -> any ScheduledRevocationExceptionStore {
        return MemoryScheduledRevocationExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledRevocationExceptionStore: ScheduledRevocationExceptionStore {
        var inner: MemoryScheduledRevocationExceptionStore
        var cache: TTLCache<ScheduledRevocationException>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledRevocationExceptionStore, cache: TTLCache<ScheduledRevocationException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledRevocationException? {
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

        func save(_ item: ScheduledRevocationException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledRevocationException] {
            return inner.list()
        }
    }

    static func newCachedScheduledRevocationExceptionStore(_ inner: MemoryScheduledRevocationExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledRevocationExceptionStore {
        return CachedScheduledRevocationExceptionStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled revocation exceptions. Empty fields match all.
    final class ScheduledRevocationExceptionQuery {
        var category: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledRevocationException) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledRevocationException]) -> [ScheduledRevocationException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledRevocationException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledRevocationExceptions(_ store: any ScheduledRevocationExceptionStore, query: ScheduledRevocationExceptionQuery) -> [ScheduledRevocationException] {
        return query.apply(store.list())
    }
}
