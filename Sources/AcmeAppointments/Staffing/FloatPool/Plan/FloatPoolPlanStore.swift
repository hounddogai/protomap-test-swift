import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool plans by code.
    protocol FloatPoolPlanStore {
        func find(_ code: String) -> FloatPoolPlan?
        func save(_ item: FloatPoolPlan)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolPlanStore: FloatPoolPlanStore {
        var items: [String: FloatPoolPlan]
        var order: [String]

        init(items: [String: FloatPoolPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolPlan) {
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

        func list() -> [FloatPoolPlan] {
            var out: [FloatPoolPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolPlanStore() -> any FloatPoolPlanStore {
        return MemoryFloatPoolPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolPlanStore: FloatPoolPlanStore {
        var inner: MemoryFloatPoolPlanStore
        var cache: TTLCache<FloatPoolPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolPlanStore, cache: TTLCache<FloatPoolPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolPlan? {
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

        func save(_ item: FloatPoolPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolPlan] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolPlanStore(_ inner: MemoryFloatPoolPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolPlanStore {
        return CachedFloatPoolPlanStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool plans. Empty fields match all.
    final class FloatPoolPlanQuery {
        var region: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolPlan) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolPlan]) -> [FloatPoolPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolPlans(_ store: any FloatPoolPlanStore, query: FloatPoolPlanQuery) -> [FloatPoolPlan] {
        return query.apply(store.list())
    }
}
