import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps weighted closure adjustments by code.
    protocol WeightedClosureAdjustmentStore {
        func find(_ code: String) -> WeightedClosureAdjustment?
        func save(_ item: WeightedClosureAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedClosureAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedClosureAdjustmentStore: WeightedClosureAdjustmentStore {
        var items: [String: WeightedClosureAdjustment]
        var order: [String]

        init(items: [String: WeightedClosureAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedClosureAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedClosureAdjustment) {
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

        func list() -> [WeightedClosureAdjustment] {
            var out: [WeightedClosureAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedClosureAdjustmentStore() -> any WeightedClosureAdjustmentStore {
        return MemoryWeightedClosureAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedClosureAdjustmentStore: WeightedClosureAdjustmentStore {
        var inner: MemoryWeightedClosureAdjustmentStore
        var cache: TTLCache<WeightedClosureAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedClosureAdjustmentStore, cache: TTLCache<WeightedClosureAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedClosureAdjustment? {
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

        func save(_ item: WeightedClosureAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedClosureAdjustment] {
            return inner.list()
        }
    }

    static func newCachedWeightedClosureAdjustmentStore(_ inner: MemoryWeightedClosureAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedClosureAdjustmentStore {
        return CachedWeightedClosureAdjustmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted closure adjustments. Empty fields match all.
    final class WeightedClosureAdjustmentQuery {
        var country: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minLimit: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedClosureAdjustment) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedClosureAdjustment]) -> [WeightedClosureAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedClosureAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedClosureAdjustments(_ store: any WeightedClosureAdjustmentStore, query: WeightedClosureAdjustmentQuery) -> [WeightedClosureAdjustment] {
        return query.apply(store.list())
    }
}
