import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps legacy inventory rollups by code.
    protocol LegacyInventoryRollupStore {
        func find(_ code: String) -> LegacyInventoryRollup?
        func save(_ item: LegacyInventoryRollup)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyInventoryRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyInventoryRollupStore: LegacyInventoryRollupStore {
        var items: [String: LegacyInventoryRollup]
        var order: [String]

        init(items: [String: LegacyInventoryRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyInventoryRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyInventoryRollup) {
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

        func list() -> [LegacyInventoryRollup] {
            var out: [LegacyInventoryRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyInventoryRollupStore() -> any LegacyInventoryRollupStore {
        return MemoryLegacyInventoryRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyInventoryRollupStore: LegacyInventoryRollupStore {
        var inner: MemoryLegacyInventoryRollupStore
        var cache: TTLCache<LegacyInventoryRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyInventoryRollupStore, cache: TTLCache<LegacyInventoryRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyInventoryRollup? {
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

        func save(_ item: LegacyInventoryRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyInventoryRollup] {
            return inner.list()
        }
    }

    static func newCachedLegacyInventoryRollupStore(_ inner: MemoryLegacyInventoryRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyInventoryRollupStore {
        return CachedLegacyInventoryRollupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy inventory rollups. Empty fields match all.
    final class LegacyInventoryRollupQuery {
        var unit: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyInventoryRollup) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyInventoryRollup]) -> [LegacyInventoryRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyInventoryRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyInventoryRollups(_ store: any LegacyInventoryRollupStore, query: LegacyInventoryRollupQuery) -> [LegacyInventoryRollup] {
        return query.apply(store.list())
    }
}
