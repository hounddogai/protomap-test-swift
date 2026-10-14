import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set cycles by code.
    protocol OrderSetCycleStore {
        func find(_ code: String) -> OrderSetCycle?
        func save(_ item: OrderSetCycle)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetCycleStore: OrderSetCycleStore {
        var items: [String: OrderSetCycle]
        var order: [String]

        init(items: [String: OrderSetCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetCycle) {
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

        func list() -> [OrderSetCycle] {
            var out: [OrderSetCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetCycleStore() -> any OrderSetCycleStore {
        return MemoryOrderSetCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetCycleStore: OrderSetCycleStore {
        var inner: MemoryOrderSetCycleStore
        var cache: TTLCache<OrderSetCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetCycleStore, cache: TTLCache<OrderSetCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetCycle? {
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

        func save(_ item: OrderSetCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetCycle] {
            return inner.list()
        }
    }

    static func newCachedOrderSetCycleStore(_ inner: MemoryOrderSetCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetCycleStore {
        return CachedOrderSetCycleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set cycles. Empty fields match all.
    final class OrderSetCycleQuery {
        var region: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetCycle) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetCycle]) -> [OrderSetCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetCycles(_ store: any OrderSetCycleStore, query: OrderSetCycleQuery) -> [OrderSetCycle] {
        return query.apply(store.list())
    }
}
