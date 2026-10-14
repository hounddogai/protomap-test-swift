import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool estimates by code.
    protocol FloatPoolEstimateStore {
        func find(_ code: String) -> FloatPoolEstimate?
        func save(_ item: FloatPoolEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolEstimateStore: FloatPoolEstimateStore {
        var items: [String: FloatPoolEstimate]
        var order: [String]

        init(items: [String: FloatPoolEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolEstimate) {
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

        func list() -> [FloatPoolEstimate] {
            var out: [FloatPoolEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolEstimateStore() -> any FloatPoolEstimateStore {
        return MemoryFloatPoolEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolEstimateStore: FloatPoolEstimateStore {
        var inner: MemoryFloatPoolEstimateStore
        var cache: TTLCache<FloatPoolEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolEstimateStore, cache: TTLCache<FloatPoolEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolEstimate? {
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

        func save(_ item: FloatPoolEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolEstimate] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolEstimateStore(_ inner: MemoryFloatPoolEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolEstimateStore {
        return CachedFloatPoolEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool estimates. Empty fields match all.
    final class FloatPoolEstimateQuery {
        var name: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolEstimate) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolEstimate]) -> [FloatPoolEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolEstimates(_ store: any FloatPoolEstimateStore, query: FloatPoolEstimateQuery) -> [FloatPoolEstimate] {
        return query.apply(store.list())
    }
}
