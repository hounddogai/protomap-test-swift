import AcmePlatform
import Foundation

extension Labs {
    /// Keeps capped courier exceptions by code.
    protocol CappedCourierExceptionStore {
        func find(_ code: String) -> CappedCourierException?
        func save(_ item: CappedCourierException)
        func remove(_ code: String) -> Bool
        func list() -> [CappedCourierException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedCourierExceptionStore: CappedCourierExceptionStore {
        var items: [String: CappedCourierException]
        var order: [String]

        init(items: [String: CappedCourierException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedCourierException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedCourierException) {
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

        func list() -> [CappedCourierException] {
            var out: [CappedCourierException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedCourierExceptionStore() -> any CappedCourierExceptionStore {
        return MemoryCappedCourierExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedCourierExceptionStore: CappedCourierExceptionStore {
        var inner: MemoryCappedCourierExceptionStore
        var cache: TTLCache<CappedCourierException>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedCourierExceptionStore, cache: TTLCache<CappedCourierException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedCourierException? {
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

        func save(_ item: CappedCourierException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedCourierException] {
            return inner.list()
        }
    }

    static func newCachedCappedCourierExceptionStore(_ inner: MemoryCappedCourierExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedCourierExceptionStore {
        return CachedCappedCourierExceptionStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped courier exceptions. Empty fields match all.
    final class CappedCourierExceptionQuery {
        var name: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedCourierException) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedCourierException]) -> [CappedCourierException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedCourierException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedCourierExceptions(_ store: any CappedCourierExceptionStore, query: CappedCourierExceptionQuery) -> [CappedCourierException] {
        return query.apply(store.list())
    }
}
