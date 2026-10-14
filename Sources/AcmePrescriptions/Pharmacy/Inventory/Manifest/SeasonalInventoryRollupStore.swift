import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps seasonal inventory rollups by code.
    protocol SeasonalInventoryRollupStore {
        func find(_ code: String) -> SeasonalInventoryRollup?
        func save(_ item: SeasonalInventoryRollup)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalInventoryRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalInventoryRollupStore: SeasonalInventoryRollupStore {
        var items: [String: SeasonalInventoryRollup]
        var order: [String]

        init(items: [String: SeasonalInventoryRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalInventoryRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalInventoryRollup) {
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

        func list() -> [SeasonalInventoryRollup] {
            var out: [SeasonalInventoryRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalInventoryRollupStore() -> any SeasonalInventoryRollupStore {
        return MemorySeasonalInventoryRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalInventoryRollupStore: SeasonalInventoryRollupStore {
        var inner: MemorySeasonalInventoryRollupStore
        var cache: TTLCache<SeasonalInventoryRollup>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalInventoryRollupStore, cache: TTLCache<SeasonalInventoryRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalInventoryRollup? {
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

        func save(_ item: SeasonalInventoryRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalInventoryRollup] {
            return inner.list()
        }
    }

    static func newCachedSeasonalInventoryRollupStore(_ inner: MemorySeasonalInventoryRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalInventoryRollupStore {
        return CachedSeasonalInventoryRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal inventory rollups. Empty fields match all.
    final class SeasonalInventoryRollupQuery {
        var category: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalInventoryRollup) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalInventoryRollup]) -> [SeasonalInventoryRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalInventoryRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalInventoryRollups(_ store: any SeasonalInventoryRollupStore, query: SeasonalInventoryRollupQuery) -> [SeasonalInventoryRollup] {
        return query.apply(store.list())
    }
}
