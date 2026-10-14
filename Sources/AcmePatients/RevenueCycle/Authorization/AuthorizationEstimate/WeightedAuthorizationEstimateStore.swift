import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps weighted authorization estimates by code.
    protocol WeightedAuthorizationEstimateStore {
        func find(_ code: String) -> WeightedAuthorizationEstimate?
        func save(_ item: WeightedAuthorizationEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedAuthorizationEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedAuthorizationEstimateStore: WeightedAuthorizationEstimateStore {
        var items: [String: WeightedAuthorizationEstimate]
        var order: [String]

        init(items: [String: WeightedAuthorizationEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedAuthorizationEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedAuthorizationEstimate) {
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

        func list() -> [WeightedAuthorizationEstimate] {
            var out: [WeightedAuthorizationEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedAuthorizationEstimateStore() -> any WeightedAuthorizationEstimateStore {
        return MemoryWeightedAuthorizationEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedAuthorizationEstimateStore: WeightedAuthorizationEstimateStore {
        var inner: MemoryWeightedAuthorizationEstimateStore
        var cache: TTLCache<WeightedAuthorizationEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedAuthorizationEstimateStore, cache: TTLCache<WeightedAuthorizationEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedAuthorizationEstimate? {
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

        func save(_ item: WeightedAuthorizationEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedAuthorizationEstimate] {
            return inner.list()
        }
    }

    static func newCachedWeightedAuthorizationEstimateStore(_ inner: MemoryWeightedAuthorizationEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedAuthorizationEstimateStore {
        return CachedWeightedAuthorizationEstimateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted authorization estimates. Empty fields match all.
    final class WeightedAuthorizationEstimateQuery {
        var locale: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minBudget: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedAuthorizationEstimate) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [WeightedAuthorizationEstimate]) -> [WeightedAuthorizationEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedAuthorizationEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedAuthorizationEstimates(_ store: any WeightedAuthorizationEstimateStore, query: WeightedAuthorizationEstimateQuery) -> [WeightedAuthorizationEstimate] {
        return query.apply(store.list())
    }
}
