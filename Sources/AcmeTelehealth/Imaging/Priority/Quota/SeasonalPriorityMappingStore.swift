import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps seasonal priority mappings by code.
    protocol SeasonalPriorityMappingStore {
        func find(_ code: String) -> SeasonalPriorityMapping?
        func save(_ item: SeasonalPriorityMapping)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalPriorityMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalPriorityMappingStore: SeasonalPriorityMappingStore {
        var items: [String: SeasonalPriorityMapping]
        var order: [String]

        init(items: [String: SeasonalPriorityMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalPriorityMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalPriorityMapping) {
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

        func list() -> [SeasonalPriorityMapping] {
            var out: [SeasonalPriorityMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalPriorityMappingStore() -> any SeasonalPriorityMappingStore {
        return MemorySeasonalPriorityMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalPriorityMappingStore: SeasonalPriorityMappingStore {
        var inner: MemorySeasonalPriorityMappingStore
        var cache: TTLCache<SeasonalPriorityMapping>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalPriorityMappingStore, cache: TTLCache<SeasonalPriorityMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalPriorityMapping? {
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

        func save(_ item: SeasonalPriorityMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalPriorityMapping] {
            return inner.list()
        }
    }

    static func newCachedSeasonalPriorityMappingStore(_ inner: MemorySeasonalPriorityMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalPriorityMappingStore {
        return CachedSeasonalPriorityMappingStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal priority mappings. Empty fields match all.
    final class SeasonalPriorityMappingQuery {
        var channel: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalPriorityMapping) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [SeasonalPriorityMapping]) -> [SeasonalPriorityMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalPriorityMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalPriorityMappings(_ store: any SeasonalPriorityMappingStore, query: SeasonalPriorityMappingQuery) -> [SeasonalPriorityMapping] {
        return query.apply(store.list())
    }
}
