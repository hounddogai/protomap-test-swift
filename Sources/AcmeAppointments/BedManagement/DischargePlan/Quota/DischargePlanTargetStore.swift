import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan targets by code.
    protocol DischargePlanTargetStore {
        func find(_ code: String) -> DischargePlanTarget?
        func save(_ item: DischargePlanTarget)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanTargetStore: DischargePlanTargetStore {
        var items: [String: DischargePlanTarget]
        var order: [String]

        init(items: [String: DischargePlanTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanTarget) {
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

        func list() -> [DischargePlanTarget] {
            var out: [DischargePlanTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanTargetStore() -> any DischargePlanTargetStore {
        return MemoryDischargePlanTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanTargetStore: DischargePlanTargetStore {
        var inner: MemoryDischargePlanTargetStore
        var cache: TTLCache<DischargePlanTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanTargetStore, cache: TTLCache<DischargePlanTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanTarget? {
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

        func save(_ item: DischargePlanTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanTarget] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanTargetStore(_ inner: MemoryDischargePlanTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanTargetStore {
        return CachedDischargePlanTargetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan targets. Empty fields match all.
    final class DischargePlanTargetQuery {
        var facility: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanTarget) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DischargePlanTarget]) -> [DischargePlanTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanTargets(_ store: any DischargePlanTargetStore, query: DischargePlanTargetQuery) -> [DischargePlanTarget] {
        return query.apply(store.list())
    }
}
