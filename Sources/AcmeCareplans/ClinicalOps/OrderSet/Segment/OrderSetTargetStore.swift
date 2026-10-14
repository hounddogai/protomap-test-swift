import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set targets by code.
    protocol OrderSetTargetStore {
        func find(_ code: String) -> OrderSetTarget?
        func save(_ item: OrderSetTarget)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetTargetStore: OrderSetTargetStore {
        var items: [String: OrderSetTarget]
        var order: [String]

        init(items: [String: OrderSetTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetTarget) {
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

        func list() -> [OrderSetTarget] {
            var out: [OrderSetTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetTargetStore() -> any OrderSetTargetStore {
        return MemoryOrderSetTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetTargetStore: OrderSetTargetStore {
        var inner: MemoryOrderSetTargetStore
        var cache: TTLCache<OrderSetTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetTargetStore, cache: TTLCache<OrderSetTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetTarget? {
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

        func save(_ item: OrderSetTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetTarget] {
            return inner.list()
        }
    }

    static func newCachedOrderSetTargetStore(_ inner: MemoryOrderSetTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetTargetStore {
        return CachedOrderSetTargetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set targets. Empty fields match all.
    final class OrderSetTargetQuery {
        var region: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetTarget) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetTarget]) -> [OrderSetTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetTargets(_ store: any OrderSetTargetStore, query: OrderSetTargetQuery) -> [OrderSetTarget] {
        return query.apply(store.list())
    }
}
