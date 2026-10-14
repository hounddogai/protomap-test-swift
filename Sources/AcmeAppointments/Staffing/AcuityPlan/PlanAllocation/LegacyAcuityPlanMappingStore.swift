import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps legacy acuity plan mappings by code.
    protocol LegacyAcuityPlanMappingStore {
        func find(_ code: String) -> LegacyAcuityPlanMapping?
        func save(_ item: LegacyAcuityPlanMapping)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyAcuityPlanMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyAcuityPlanMappingStore: LegacyAcuityPlanMappingStore {
        var items: [String: LegacyAcuityPlanMapping]
        var order: [String]

        init(items: [String: LegacyAcuityPlanMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyAcuityPlanMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyAcuityPlanMapping) {
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

        func list() -> [LegacyAcuityPlanMapping] {
            var out: [LegacyAcuityPlanMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyAcuityPlanMappingStore() -> any LegacyAcuityPlanMappingStore {
        return MemoryLegacyAcuityPlanMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyAcuityPlanMappingStore: LegacyAcuityPlanMappingStore {
        var inner: MemoryLegacyAcuityPlanMappingStore
        var cache: TTLCache<LegacyAcuityPlanMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyAcuityPlanMappingStore, cache: TTLCache<LegacyAcuityPlanMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyAcuityPlanMapping? {
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

        func save(_ item: LegacyAcuityPlanMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyAcuityPlanMapping] {
            return inner.list()
        }
    }

    static func newCachedLegacyAcuityPlanMappingStore(_ inner: MemoryLegacyAcuityPlanMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyAcuityPlanMappingStore {
        return CachedLegacyAcuityPlanMappingStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy acuity plan mappings. Empty fields match all.
    final class LegacyAcuityPlanMappingQuery {
        var facility: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minMargin: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyAcuityPlanMapping) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyAcuityPlanMapping]) -> [LegacyAcuityPlanMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyAcuityPlanMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyAcuityPlanMappings(_ store: any LegacyAcuityPlanMappingStore, query: LegacyAcuityPlanMappingQuery) -> [LegacyAcuityPlanMapping] {
        return query.apply(store.list())
    }
}
