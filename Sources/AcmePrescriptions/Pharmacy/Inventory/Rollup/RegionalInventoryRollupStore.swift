import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps regional inventory rollups by code.
    protocol RegionalInventoryRollupStore {
        func find(_ code: String) -> RegionalInventoryRollup?
        func save(_ item: RegionalInventoryRollup)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalInventoryRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalInventoryRollupStore: RegionalInventoryRollupStore {
        var items: [String: RegionalInventoryRollup]
        var order: [String]

        init(items: [String: RegionalInventoryRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalInventoryRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalInventoryRollup) {
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

        func list() -> [RegionalInventoryRollup] {
            var out: [RegionalInventoryRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalInventoryRollupStore() -> any RegionalInventoryRollupStore {
        return MemoryRegionalInventoryRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalInventoryRollupStore: RegionalInventoryRollupStore {
        var inner: MemoryRegionalInventoryRollupStore
        var cache: TTLCache<RegionalInventoryRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalInventoryRollupStore, cache: TTLCache<RegionalInventoryRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalInventoryRollup? {
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

        func save(_ item: RegionalInventoryRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalInventoryRollup] {
            return inner.list()
        }
    }

    static func newCachedRegionalInventoryRollupStore(_ inner: MemoryRegionalInventoryRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalInventoryRollupStore {
        return CachedRegionalInventoryRollupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional inventory rollups. Empty fields match all.
    final class RegionalInventoryRollupQuery {
        var source: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minSequence: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalInventoryRollup) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalInventoryRollup]) -> [RegionalInventoryRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalInventoryRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalInventoryRollups(_ store: any RegionalInventoryRollupStore, query: RegionalInventoryRollupQuery) -> [RegionalInventoryRollup] {
        return query.apply(store.list())
    }
}
