import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps rolling assessment mappings by code.
    protocol RollingAssessmentMappingStore {
        func find(_ code: String) -> RollingAssessmentMapping?
        func save(_ item: RollingAssessmentMapping)
        func remove(_ code: String) -> Bool
        func list() -> [RollingAssessmentMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingAssessmentMappingStore: RollingAssessmentMappingStore {
        var items: [String: RollingAssessmentMapping]
        var order: [String]

        init(items: [String: RollingAssessmentMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingAssessmentMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingAssessmentMapping) {
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

        func list() -> [RollingAssessmentMapping] {
            var out: [RollingAssessmentMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingAssessmentMappingStore() -> any RollingAssessmentMappingStore {
        return MemoryRollingAssessmentMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingAssessmentMappingStore: RollingAssessmentMappingStore {
        var inner: MemoryRollingAssessmentMappingStore
        var cache: TTLCache<RollingAssessmentMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingAssessmentMappingStore, cache: TTLCache<RollingAssessmentMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingAssessmentMapping? {
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

        func save(_ item: RollingAssessmentMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingAssessmentMapping] {
            return inner.list()
        }
    }

    static func newCachedRollingAssessmentMappingStore(_ inner: MemoryRollingAssessmentMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingAssessmentMappingStore {
        return CachedRollingAssessmentMappingStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling assessment mappings. Empty fields match all.
    final class RollingAssessmentMappingQuery {
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

        func matches(_ item: RollingAssessmentMapping) -> Bool {
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

        func apply(_ items: [RollingAssessmentMapping]) -> [RollingAssessmentMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingAssessmentMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingAssessmentMappings(_ store: any RollingAssessmentMappingStore, query: RollingAssessmentMappingQuery) -> [RollingAssessmentMapping] {
        return query.apply(store.list())
    }
}
