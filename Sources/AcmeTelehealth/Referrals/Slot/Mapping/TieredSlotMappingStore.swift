import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps tiered slot mappings by code.
    protocol TieredSlotMappingStore {
        func find(_ code: String) -> TieredSlotMapping?
        func save(_ item: TieredSlotMapping)
        func remove(_ code: String) -> Bool
        func list() -> [TieredSlotMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredSlotMappingStore: TieredSlotMappingStore {
        var items: [String: TieredSlotMapping]
        var order: [String]

        init(items: [String: TieredSlotMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredSlotMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredSlotMapping) {
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

        func list() -> [TieredSlotMapping] {
            var out: [TieredSlotMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredSlotMappingStore() -> any TieredSlotMappingStore {
        return MemoryTieredSlotMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredSlotMappingStore: TieredSlotMappingStore {
        var inner: MemoryTieredSlotMappingStore
        var cache: TTLCache<TieredSlotMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredSlotMappingStore, cache: TTLCache<TieredSlotMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredSlotMapping? {
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

        func save(_ item: TieredSlotMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredSlotMapping] {
            return inner.list()
        }
    }

    static func newCachedTieredSlotMappingStore(_ inner: MemoryTieredSlotMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredSlotMappingStore {
        return CachedTieredSlotMappingStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered slot mappings. Empty fields match all.
    final class TieredSlotMappingQuery {
        var category: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredSlotMapping) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredSlotMapping]) -> [TieredSlotMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredSlotMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredSlotMappings(_ store: any TieredSlotMappingStore, query: TieredSlotMappingQuery) -> [TieredSlotMapping] {
        return query.apply(store.list())
    }
}
