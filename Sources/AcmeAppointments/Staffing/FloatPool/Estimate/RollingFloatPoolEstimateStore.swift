import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps rolling float pool estimates by code.
    protocol RollingFloatPoolEstimateStore {
        func find(_ code: String) -> RollingFloatPoolEstimate?
        func save(_ item: RollingFloatPoolEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [RollingFloatPoolEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingFloatPoolEstimateStore: RollingFloatPoolEstimateStore {
        var items: [String: RollingFloatPoolEstimate]
        var order: [String]

        init(items: [String: RollingFloatPoolEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingFloatPoolEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingFloatPoolEstimate) {
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

        func list() -> [RollingFloatPoolEstimate] {
            var out: [RollingFloatPoolEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingFloatPoolEstimateStore() -> any RollingFloatPoolEstimateStore {
        return MemoryRollingFloatPoolEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingFloatPoolEstimateStore: RollingFloatPoolEstimateStore {
        var inner: MemoryRollingFloatPoolEstimateStore
        var cache: TTLCache<RollingFloatPoolEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingFloatPoolEstimateStore, cache: TTLCache<RollingFloatPoolEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingFloatPoolEstimate? {
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

        func save(_ item: RollingFloatPoolEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingFloatPoolEstimate] {
            return inner.list()
        }
    }

    static func newCachedRollingFloatPoolEstimateStore(_ inner: MemoryRollingFloatPoolEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingFloatPoolEstimateStore {
        return CachedRollingFloatPoolEstimateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling float pool estimates. Empty fields match all.
    final class RollingFloatPoolEstimateQuery {
        var segment: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minWeight: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingFloatPoolEstimate) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingFloatPoolEstimate]) -> [RollingFloatPoolEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingFloatPoolEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingFloatPoolEstimates(_ store: any RollingFloatPoolEstimateStore, query: RollingFloatPoolEstimateQuery) -> [RollingFloatPoolEstimate] {
        return query.apply(store.list())
    }
}
