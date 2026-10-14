import AcmePlatform
import Foundation

extension Labs {
    /// Keeps fallback courier exceptions by code.
    protocol FallbackCourierExceptionStore {
        func find(_ code: String) -> FallbackCourierException?
        func save(_ item: FallbackCourierException)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackCourierException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackCourierExceptionStore: FallbackCourierExceptionStore {
        var items: [String: FallbackCourierException]
        var order: [String]

        init(items: [String: FallbackCourierException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackCourierException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackCourierException) {
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

        func list() -> [FallbackCourierException] {
            var out: [FallbackCourierException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackCourierExceptionStore() -> any FallbackCourierExceptionStore {
        return MemoryFallbackCourierExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackCourierExceptionStore: FallbackCourierExceptionStore {
        var inner: MemoryFallbackCourierExceptionStore
        var cache: TTLCache<FallbackCourierException>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackCourierExceptionStore, cache: TTLCache<FallbackCourierException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackCourierException? {
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

        func save(_ item: FallbackCourierException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackCourierException] {
            return inner.list()
        }
    }

    static func newCachedFallbackCourierExceptionStore(_ inner: MemoryFallbackCourierExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackCourierExceptionStore {
        return CachedFallbackCourierExceptionStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback courier exceptions. Empty fields match all.
    final class FallbackCourierExceptionQuery {
        var title: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackCourierException) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackCourierException]) -> [FallbackCourierException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackCourierException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackCourierExceptions(_ store: any FallbackCourierExceptionStore, query: FallbackCourierExceptionQuery) -> [FallbackCourierException] {
        return query.apply(store.list())
    }
}
