import AcmePlatform
import Foundation

extension Labs {
    /// Keeps weighted courier exceptions by code.
    protocol WeightedCourierExceptionStore {
        func find(_ code: String) -> WeightedCourierException?
        func save(_ item: WeightedCourierException)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedCourierException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedCourierExceptionStore: WeightedCourierExceptionStore {
        var items: [String: WeightedCourierException]
        var order: [String]

        init(items: [String: WeightedCourierException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedCourierException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedCourierException) {
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

        func list() -> [WeightedCourierException] {
            var out: [WeightedCourierException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedCourierExceptionStore() -> any WeightedCourierExceptionStore {
        return MemoryWeightedCourierExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedCourierExceptionStore: WeightedCourierExceptionStore {
        var inner: MemoryWeightedCourierExceptionStore
        var cache: TTLCache<WeightedCourierException>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedCourierExceptionStore, cache: TTLCache<WeightedCourierException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedCourierException? {
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

        func save(_ item: WeightedCourierException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedCourierException] {
            return inner.list()
        }
    }

    static func newCachedWeightedCourierExceptionStore(_ inner: MemoryWeightedCourierExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedCourierExceptionStore {
        return CachedWeightedCourierExceptionStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted courier exceptions. Empty fields match all.
    final class WeightedCourierExceptionQuery {
        var segment: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedCourierException) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedCourierException]) -> [WeightedCourierException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedCourierException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedCourierExceptions(_ store: any WeightedCourierExceptionStore, query: WeightedCourierExceptionQuery) -> [WeightedCourierException] {
        return query.apply(store.list())
    }
}
