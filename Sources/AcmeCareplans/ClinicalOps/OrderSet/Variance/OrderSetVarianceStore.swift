import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set variances by code.
    protocol OrderSetVarianceStore {
        func find(_ code: String) -> OrderSetVariance?
        func save(_ item: OrderSetVariance)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetVarianceStore: OrderSetVarianceStore {
        var items: [String: OrderSetVariance]
        var order: [String]

        init(items: [String: OrderSetVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetVariance) {
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

        func list() -> [OrderSetVariance] {
            var out: [OrderSetVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetVarianceStore() -> any OrderSetVarianceStore {
        return MemoryOrderSetVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetVarianceStore: OrderSetVarianceStore {
        var inner: MemoryOrderSetVarianceStore
        var cache: TTLCache<OrderSetVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetVarianceStore, cache: TTLCache<OrderSetVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetVariance? {
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

        func save(_ item: OrderSetVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetVariance] {
            return inner.list()
        }
    }

    static func newCachedOrderSetVarianceStore(_ inner: MemoryOrderSetVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetVarianceStore {
        return CachedOrderSetVarianceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set variances. Empty fields match all.
    final class OrderSetVarianceQuery {
        var category: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetVariance) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetVariance]) -> [OrderSetVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetVariances(_ store: any OrderSetVarianceStore, query: OrderSetVarianceQuery) -> [OrderSetVariance] {
        return query.apply(store.list())
    }
}
