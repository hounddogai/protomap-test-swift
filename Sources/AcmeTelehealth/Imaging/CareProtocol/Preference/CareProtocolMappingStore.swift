import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol mappings by code.
    protocol CareProtocolMappingStore {
        func find(_ code: String) -> CareProtocolMapping?
        func save(_ item: CareProtocolMapping)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolMappingStore: CareProtocolMappingStore {
        var items: [String: CareProtocolMapping]
        var order: [String]

        init(items: [String: CareProtocolMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolMapping) {
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

        func list() -> [CareProtocolMapping] {
            var out: [CareProtocolMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolMappingStore() -> any CareProtocolMappingStore {
        return MemoryCareProtocolMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolMappingStore: CareProtocolMappingStore {
        var inner: MemoryCareProtocolMappingStore
        var cache: TTLCache<CareProtocolMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolMappingStore, cache: TTLCache<CareProtocolMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolMapping? {
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

        func save(_ item: CareProtocolMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolMapping] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolMappingStore(_ inner: MemoryCareProtocolMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolMappingStore {
        return CachedCareProtocolMappingStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol mappings. Empty fields match all.
    final class CareProtocolMappingQuery {
        var facility: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minBudget: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolMapping) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolMapping]) -> [CareProtocolMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolMappings(_ store: any CareProtocolMappingStore, query: CareProtocolMappingQuery) -> [CareProtocolMapping] {
        return query.apply(store.list())
    }
}
