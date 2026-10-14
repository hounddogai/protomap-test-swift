import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps adaptive discharge plan mappings by code.
    protocol AdaptiveDischargePlanMappingStore {
        func find(_ code: String) -> AdaptiveDischargePlanMapping?
        func save(_ item: AdaptiveDischargePlanMapping)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveDischargePlanMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveDischargePlanMappingStore: AdaptiveDischargePlanMappingStore {
        var items: [String: AdaptiveDischargePlanMapping]
        var order: [String]

        init(items: [String: AdaptiveDischargePlanMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveDischargePlanMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveDischargePlanMapping) {
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

        func list() -> [AdaptiveDischargePlanMapping] {
            var out: [AdaptiveDischargePlanMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveDischargePlanMappingStore() -> any AdaptiveDischargePlanMappingStore {
        return MemoryAdaptiveDischargePlanMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveDischargePlanMappingStore: AdaptiveDischargePlanMappingStore {
        var inner: MemoryAdaptiveDischargePlanMappingStore
        var cache: TTLCache<AdaptiveDischargePlanMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveDischargePlanMappingStore, cache: TTLCache<AdaptiveDischargePlanMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveDischargePlanMapping? {
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

        func save(_ item: AdaptiveDischargePlanMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveDischargePlanMapping] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveDischargePlanMappingStore(_ inner: MemoryAdaptiveDischargePlanMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveDischargePlanMappingStore {
        return CachedAdaptiveDischargePlanMappingStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive discharge plan mappings. Empty fields match all.
    final class AdaptiveDischargePlanMappingQuery {
        var region: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveDischargePlanMapping) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveDischargePlanMapping]) -> [AdaptiveDischargePlanMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveDischargePlanMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveDischargePlanMappings(_ store: any AdaptiveDischargePlanMappingStore, query: AdaptiveDischargePlanMappingQuery) -> [AdaptiveDischargePlanMapping] {
        return query.apply(store.list())
    }
}
