import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier estimates by code.
    protocol CourierEstimateStore {
        func find(_ code: String) -> CourierEstimate?
        func save(_ item: CourierEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [CourierEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierEstimateStore: CourierEstimateStore {
        var items: [String: CourierEstimate]
        var order: [String]

        init(items: [String: CourierEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierEstimate) {
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

        func list() -> [CourierEstimate] {
            var out: [CourierEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierEstimateStore() -> any CourierEstimateStore {
        return MemoryCourierEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierEstimateStore: CourierEstimateStore {
        var inner: MemoryCourierEstimateStore
        var cache: TTLCache<CourierEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierEstimateStore, cache: TTLCache<CourierEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierEstimate? {
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

        func save(_ item: CourierEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierEstimate] {
            return inner.list()
        }
    }

    static func newCachedCourierEstimateStore(_ inner: MemoryCourierEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierEstimateStore {
        return CachedCourierEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier estimates. Empty fields match all.
    final class CourierEstimateQuery {
        var source: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minRefills: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CourierEstimate) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CourierEstimate]) -> [CourierEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierEstimates(_ store: any CourierEstimateStore, query: CourierEstimateQuery) -> [CourierEstimate] {
        return query.apply(store.list())
    }
}
