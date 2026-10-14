import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority variances by code.
    protocol PriorityVarianceStore {
        func find(_ code: String) -> PriorityVariance?
        func save(_ item: PriorityVariance)
        func remove(_ code: String) -> Bool
        func list() -> [PriorityVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPriorityVarianceStore: PriorityVarianceStore {
        var items: [String: PriorityVariance]
        var order: [String]

        init(items: [String: PriorityVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PriorityVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PriorityVariance) {
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

        func list() -> [PriorityVariance] {
            var out: [PriorityVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPriorityVarianceStore() -> any PriorityVarianceStore {
        return MemoryPriorityVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPriorityVarianceStore: PriorityVarianceStore {
        var inner: MemoryPriorityVarianceStore
        var cache: TTLCache<PriorityVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryPriorityVarianceStore, cache: TTLCache<PriorityVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PriorityVariance? {
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

        func save(_ item: PriorityVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PriorityVariance] {
            return inner.list()
        }
    }

    static func newCachedPriorityVarianceStore(_ inner: MemoryPriorityVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PriorityVarianceStore {
        return CachedPriorityVarianceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority variances. Empty fields match all.
    final class PriorityVarianceQuery {
        var category: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minCost: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PriorityVariance) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PriorityVariance]) -> [PriorityVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PriorityVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPriorityVariances(_ store: any PriorityVarianceStore, query: PriorityVarianceQuery) -> [PriorityVariance] {
        return query.apply(store.list())
    }
}
