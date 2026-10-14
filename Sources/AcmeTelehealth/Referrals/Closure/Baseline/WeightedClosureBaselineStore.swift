import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps weighted closure baselines by code.
    protocol WeightedClosureBaselineStore {
        func find(_ code: String) -> WeightedClosureBaseline?
        func save(_ item: WeightedClosureBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedClosureBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedClosureBaselineStore: WeightedClosureBaselineStore {
        var items: [String: WeightedClosureBaseline]
        var order: [String]

        init(items: [String: WeightedClosureBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedClosureBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedClosureBaseline) {
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

        func list() -> [WeightedClosureBaseline] {
            var out: [WeightedClosureBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedClosureBaselineStore() -> any WeightedClosureBaselineStore {
        return MemoryWeightedClosureBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedClosureBaselineStore: WeightedClosureBaselineStore {
        var inner: MemoryWeightedClosureBaselineStore
        var cache: TTLCache<WeightedClosureBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedClosureBaselineStore, cache: TTLCache<WeightedClosureBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedClosureBaseline? {
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

        func save(_ item: WeightedClosureBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedClosureBaseline] {
            return inner.list()
        }
    }

    static func newCachedWeightedClosureBaselineStore(_ inner: MemoryWeightedClosureBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedClosureBaselineStore {
        return CachedWeightedClosureBaselineStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted closure baselines. Empty fields match all.
    final class WeightedClosureBaselineQuery {
        var name: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedClosureBaseline) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedClosureBaseline]) -> [WeightedClosureBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedClosureBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedClosureBaselines(_ store: any WeightedClosureBaselineStore, query: WeightedClosureBaselineQuery) -> [WeightedClosureBaseline] {
        return query.apply(store.list())
    }
}
