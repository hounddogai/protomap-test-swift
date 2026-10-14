import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan mappings by code.
    protocol AcuityPlanMappingStore {
        func find(_ code: String) -> AcuityPlanMapping?
        func save(_ item: AcuityPlanMapping)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanMappingStore: AcuityPlanMappingStore {
        var items: [String: AcuityPlanMapping]
        var order: [String]

        init(items: [String: AcuityPlanMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanMapping) {
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

        func list() -> [AcuityPlanMapping] {
            var out: [AcuityPlanMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanMappingStore() -> any AcuityPlanMappingStore {
        return MemoryAcuityPlanMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanMappingStore: AcuityPlanMappingStore {
        var inner: MemoryAcuityPlanMappingStore
        var cache: TTLCache<AcuityPlanMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanMappingStore, cache: TTLCache<AcuityPlanMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanMapping? {
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

        func save(_ item: AcuityPlanMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanMapping] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanMappingStore(_ inner: MemoryAcuityPlanMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanMappingStore {
        return CachedAcuityPlanMappingStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan mappings. Empty fields match all.
    final class AcuityPlanMappingQuery {
        var title: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanMapping) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AcuityPlanMapping]) -> [AcuityPlanMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanMappings(_ store: any AcuityPlanMappingStore, query: AcuityPlanMappingQuery) -> [AcuityPlanMapping] {
        return query.apply(store.list())
    }
}
