import AcmePlatform
import Foundation

extension Labs {
    /// Keeps regional reference range mappings by code.
    protocol RegionalReferenceRangeMappingStore {
        func find(_ code: String) -> RegionalReferenceRangeMapping?
        func save(_ item: RegionalReferenceRangeMapping)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalReferenceRangeMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalReferenceRangeMappingStore: RegionalReferenceRangeMappingStore {
        var items: [String: RegionalReferenceRangeMapping]
        var order: [String]

        init(items: [String: RegionalReferenceRangeMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalReferenceRangeMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalReferenceRangeMapping) {
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

        func list() -> [RegionalReferenceRangeMapping] {
            var out: [RegionalReferenceRangeMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalReferenceRangeMappingStore() -> any RegionalReferenceRangeMappingStore {
        return MemoryRegionalReferenceRangeMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalReferenceRangeMappingStore: RegionalReferenceRangeMappingStore {
        var inner: MemoryRegionalReferenceRangeMappingStore
        var cache: TTLCache<RegionalReferenceRangeMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalReferenceRangeMappingStore, cache: TTLCache<RegionalReferenceRangeMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalReferenceRangeMapping? {
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

        func save(_ item: RegionalReferenceRangeMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalReferenceRangeMapping] {
            return inner.list()
        }
    }

    static func newCachedRegionalReferenceRangeMappingStore(_ inner: MemoryRegionalReferenceRangeMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalReferenceRangeMappingStore {
        return CachedRegionalReferenceRangeMappingStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional reference range mappings. Empty fields match all.
    final class RegionalReferenceRangeMappingQuery {
        var name: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalReferenceRangeMapping) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalReferenceRangeMapping]) -> [RegionalReferenceRangeMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalReferenceRangeMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalReferenceRangeMappings(_ store: any RegionalReferenceRangeMappingStore, query: RegionalReferenceRangeMappingQuery) -> [RegionalReferenceRangeMapping] {
        return query.apply(store.list())
    }
}
