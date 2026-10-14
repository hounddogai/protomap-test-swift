import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps seasonal slot mappings by code.
    protocol SeasonalSlotMappingStore {
        func find(_ code: String) -> SeasonalSlotMapping?
        func save(_ item: SeasonalSlotMapping)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalSlotMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalSlotMappingStore: SeasonalSlotMappingStore {
        var items: [String: SeasonalSlotMapping]
        var order: [String]

        init(items: [String: SeasonalSlotMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalSlotMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalSlotMapping) {
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

        func list() -> [SeasonalSlotMapping] {
            var out: [SeasonalSlotMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalSlotMappingStore() -> any SeasonalSlotMappingStore {
        return MemorySeasonalSlotMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalSlotMappingStore: SeasonalSlotMappingStore {
        var inner: MemorySeasonalSlotMappingStore
        var cache: TTLCache<SeasonalSlotMapping>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalSlotMappingStore, cache: TTLCache<SeasonalSlotMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalSlotMapping? {
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

        func save(_ item: SeasonalSlotMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalSlotMapping] {
            return inner.list()
        }
    }

    static func newCachedSeasonalSlotMappingStore(_ inner: MemorySeasonalSlotMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalSlotMappingStore {
        return CachedSeasonalSlotMappingStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal slot mappings. Empty fields match all.
    final class SeasonalSlotMappingQuery {
        var name: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRefills: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalSlotMapping) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalSlotMapping]) -> [SeasonalSlotMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalSlotMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalSlotMappings(_ store: any SeasonalSlotMappingStore, query: SeasonalSlotMappingQuery) -> [SeasonalSlotMapping] {
        return query.apply(store.list())
    }
}
