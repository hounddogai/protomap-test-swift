import AcmePlatform
import Foundation

extension Labs {
    /// Keeps weighted accession mappings by code.
    protocol WeightedAccessionMappingStore {
        func find(_ code: String) -> WeightedAccessionMapping?
        func save(_ item: WeightedAccessionMapping)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedAccessionMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedAccessionMappingStore: WeightedAccessionMappingStore {
        var items: [String: WeightedAccessionMapping]
        var order: [String]

        init(items: [String: WeightedAccessionMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedAccessionMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedAccessionMapping) {
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

        func list() -> [WeightedAccessionMapping] {
            var out: [WeightedAccessionMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedAccessionMappingStore() -> any WeightedAccessionMappingStore {
        return MemoryWeightedAccessionMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedAccessionMappingStore: WeightedAccessionMappingStore {
        var inner: MemoryWeightedAccessionMappingStore
        var cache: TTLCache<WeightedAccessionMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedAccessionMappingStore, cache: TTLCache<WeightedAccessionMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedAccessionMapping? {
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

        func save(_ item: WeightedAccessionMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedAccessionMapping] {
            return inner.list()
        }
    }

    static func newCachedWeightedAccessionMappingStore(_ inner: MemoryWeightedAccessionMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedAccessionMappingStore {
        return CachedWeightedAccessionMappingStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted accession mappings. Empty fields match all.
    final class WeightedAccessionMappingQuery {
        var region: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minPriority: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedAccessionMapping) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedAccessionMapping]) -> [WeightedAccessionMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedAccessionMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedAccessionMappings(_ store: any WeightedAccessionMappingStore, query: WeightedAccessionMappingQuery) -> [WeightedAccessionMapping] {
        return query.apply(store.list())
    }
}
