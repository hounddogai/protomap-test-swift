import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory overrides by code.
    protocol InventoryOverrideStore {
        func find(_ code: String) -> InventoryOverride?
        func save(_ item: InventoryOverride)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryOverrideStore: InventoryOverrideStore {
        var items: [String: InventoryOverride]
        var order: [String]

        init(items: [String: InventoryOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryOverride) {
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

        func list() -> [InventoryOverride] {
            var out: [InventoryOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryOverrideStore() -> any InventoryOverrideStore {
        return MemoryInventoryOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryOverrideStore: InventoryOverrideStore {
        var inner: MemoryInventoryOverrideStore
        var cache: TTLCache<InventoryOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryOverrideStore, cache: TTLCache<InventoryOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryOverride? {
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

        func save(_ item: InventoryOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryOverride] {
            return inner.list()
        }
    }

    static func newCachedInventoryOverrideStore(_ inner: MemoryInventoryOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryOverrideStore {
        return CachedInventoryOverrideStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory overrides. Empty fields match all.
    final class InventoryOverrideQuery {
        var unit: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minLimit: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventoryOverride) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InventoryOverride]) -> [InventoryOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryOverrides(_ store: any InventoryOverrideStore, query: InventoryOverrideQuery) -> [InventoryOverride] {
        return query.apply(store.list())
    }
}
