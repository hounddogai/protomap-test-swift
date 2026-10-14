import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense plans by code.
    protocol DispensePlanStore {
        func find(_ code: String) -> DispensePlan?
        func save(_ item: DispensePlan)
        func remove(_ code: String) -> Bool
        func list() -> [DispensePlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispensePlanStore: DispensePlanStore {
        var items: [String: DispensePlan]
        var order: [String]

        init(items: [String: DispensePlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispensePlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispensePlan) {
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

        func list() -> [DispensePlan] {
            var out: [DispensePlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispensePlanStore() -> any DispensePlanStore {
        return MemoryDispensePlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispensePlanStore: DispensePlanStore {
        var inner: MemoryDispensePlanStore
        var cache: TTLCache<DispensePlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispensePlanStore, cache: TTLCache<DispensePlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispensePlan? {
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

        func save(_ item: DispensePlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispensePlan] {
            return inner.list()
        }
    }

    static func newCachedDispensePlanStore(_ inner: MemoryDispensePlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispensePlanStore {
        return CachedDispensePlanStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense plans. Empty fields match all.
    final class DispensePlanQuery {
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

        func matches(_ item: DispensePlan) -> Bool {
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

        func apply(_ items: [DispensePlan]) -> [DispensePlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispensePlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispensePlans(_ store: any DispensePlanStore, query: DispensePlanQuery) -> [DispensePlan] {
        return query.apply(store.list())
    }
}
