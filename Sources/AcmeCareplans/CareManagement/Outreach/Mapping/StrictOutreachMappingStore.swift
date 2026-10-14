import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps strict outreach mappings by code.
    protocol StrictOutreachMappingStore {
        func find(_ code: String) -> StrictOutreachMapping?
        func save(_ item: StrictOutreachMapping)
        func remove(_ code: String) -> Bool
        func list() -> [StrictOutreachMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictOutreachMappingStore: StrictOutreachMappingStore {
        var items: [String: StrictOutreachMapping]
        var order: [String]

        init(items: [String: StrictOutreachMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictOutreachMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictOutreachMapping) {
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

        func list() -> [StrictOutreachMapping] {
            var out: [StrictOutreachMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictOutreachMappingStore() -> any StrictOutreachMappingStore {
        return MemoryStrictOutreachMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictOutreachMappingStore: StrictOutreachMappingStore {
        var inner: MemoryStrictOutreachMappingStore
        var cache: TTLCache<StrictOutreachMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictOutreachMappingStore, cache: TTLCache<StrictOutreachMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictOutreachMapping? {
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

        func save(_ item: StrictOutreachMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictOutreachMapping] {
            return inner.list()
        }
    }

    static func newCachedStrictOutreachMappingStore(_ inner: MemoryStrictOutreachMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictOutreachMappingStore {
        return CachedStrictOutreachMappingStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict outreach mappings. Empty fields match all.
    final class StrictOutreachMappingQuery {
        var segment: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictOutreachMapping) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictOutreachMapping]) -> [StrictOutreachMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictOutreachMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictOutreachMappings(_ store: any StrictOutreachMappingStore, query: StrictOutreachMappingQuery) -> [StrictOutreachMapping] {
        return query.apply(store.list())
    }
}
