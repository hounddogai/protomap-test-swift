import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set quotas by code.
    protocol OrderSetQuotaStore {
        func find(_ code: String) -> OrderSetQuota?
        func save(_ item: OrderSetQuota)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetQuotaStore: OrderSetQuotaStore {
        var items: [String: OrderSetQuota]
        var order: [String]

        init(items: [String: OrderSetQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetQuota) {
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

        func list() -> [OrderSetQuota] {
            var out: [OrderSetQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetQuotaStore() -> any OrderSetQuotaStore {
        return MemoryOrderSetQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetQuotaStore: OrderSetQuotaStore {
        var inner: MemoryOrderSetQuotaStore
        var cache: TTLCache<OrderSetQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetQuotaStore, cache: TTLCache<OrderSetQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetQuota? {
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

        func save(_ item: OrderSetQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetQuota] {
            return inner.list()
        }
    }

    static func newCachedOrderSetQuotaStore(_ inner: MemoryOrderSetQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetQuotaStore {
        return CachedOrderSetQuotaStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set quotas. Empty fields match all.
    final class OrderSetQuotaQuery {
        var country: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minCost: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetQuota) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [OrderSetQuota]) -> [OrderSetQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetQuotas(_ store: any OrderSetQuotaStore, query: OrderSetQuotaQuery) -> [OrderSetQuota] {
        return query.apply(store.list())
    }
}
