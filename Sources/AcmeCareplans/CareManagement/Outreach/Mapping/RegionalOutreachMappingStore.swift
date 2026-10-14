import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps regional outreach mappings by code.
    protocol RegionalOutreachMappingStore {
        func find(_ code: String) -> RegionalOutreachMapping?
        func save(_ item: RegionalOutreachMapping)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalOutreachMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalOutreachMappingStore: RegionalOutreachMappingStore {
        var items: [String: RegionalOutreachMapping]
        var order: [String]

        init(items: [String: RegionalOutreachMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalOutreachMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalOutreachMapping) {
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

        func list() -> [RegionalOutreachMapping] {
            var out: [RegionalOutreachMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalOutreachMappingStore() -> any RegionalOutreachMappingStore {
        return MemoryRegionalOutreachMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalOutreachMappingStore: RegionalOutreachMappingStore {
        var inner: MemoryRegionalOutreachMappingStore
        var cache: TTLCache<RegionalOutreachMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalOutreachMappingStore, cache: TTLCache<RegionalOutreachMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalOutreachMapping? {
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

        func save(_ item: RegionalOutreachMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalOutreachMapping] {
            return inner.list()
        }
    }

    static func newCachedRegionalOutreachMappingStore(_ inner: MemoryRegionalOutreachMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalOutreachMappingStore {
        return CachedRegionalOutreachMappingStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional outreach mappings. Empty fields match all.
    final class RegionalOutreachMappingQuery {
        var facility: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minRate: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalOutreachMapping) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalOutreachMapping]) -> [RegionalOutreachMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalOutreachMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalOutreachMappings(_ store: any RegionalOutreachMappingStore, query: RegionalOutreachMappingQuery) -> [RegionalOutreachMapping] {
        return query.apply(store.list())
    }
}
