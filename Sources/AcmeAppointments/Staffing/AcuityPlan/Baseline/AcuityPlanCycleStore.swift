import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan cycles by code.
    protocol AcuityPlanCycleStore {
        func find(_ code: String) -> AcuityPlanCycle?
        func save(_ item: AcuityPlanCycle)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanCycleStore: AcuityPlanCycleStore {
        var items: [String: AcuityPlanCycle]
        var order: [String]

        init(items: [String: AcuityPlanCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanCycle) {
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

        func list() -> [AcuityPlanCycle] {
            var out: [AcuityPlanCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanCycleStore() -> any AcuityPlanCycleStore {
        return MemoryAcuityPlanCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanCycleStore: AcuityPlanCycleStore {
        var inner: MemoryAcuityPlanCycleStore
        var cache: TTLCache<AcuityPlanCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanCycleStore, cache: TTLCache<AcuityPlanCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanCycle? {
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

        func save(_ item: AcuityPlanCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanCycle] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanCycleStore(_ inner: MemoryAcuityPlanCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanCycleStore {
        return CachedAcuityPlanCycleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan cycles. Empty fields match all.
    final class AcuityPlanCycleQuery {
        var unit: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanCycle) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AcuityPlanCycle]) -> [AcuityPlanCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanCycles(_ store: any AcuityPlanCycleStore, query: AcuityPlanCycleQuery) -> [AcuityPlanCycle] {
        return query.apply(store.list())
    }
}
