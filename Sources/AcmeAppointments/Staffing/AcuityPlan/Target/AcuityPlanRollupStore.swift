import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan rollups by code.
    protocol AcuityPlanRollupStore {
        func find(_ code: String) -> AcuityPlanRollup?
        func save(_ item: AcuityPlanRollup)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanRollupStore: AcuityPlanRollupStore {
        var items: [String: AcuityPlanRollup]
        var order: [String]

        init(items: [String: AcuityPlanRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanRollup) {
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

        func list() -> [AcuityPlanRollup] {
            var out: [AcuityPlanRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanRollupStore() -> any AcuityPlanRollupStore {
        return MemoryAcuityPlanRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanRollupStore: AcuityPlanRollupStore {
        var inner: MemoryAcuityPlanRollupStore
        var cache: TTLCache<AcuityPlanRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanRollupStore, cache: TTLCache<AcuityPlanRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanRollup? {
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

        func save(_ item: AcuityPlanRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanRollup] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanRollupStore(_ inner: MemoryAcuityPlanRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanRollupStore {
        return CachedAcuityPlanRollupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan rollups. Empty fields match all.
    final class AcuityPlanRollupQuery {
        var facility: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanRollup) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AcuityPlanRollup]) -> [AcuityPlanRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanRollups(_ store: any AcuityPlanRollupStore, query: AcuityPlanRollupQuery) -> [AcuityPlanRollup] {
        return query.apply(store.list())
    }
}
