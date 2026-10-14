import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory thresholds by code.
    protocol InventoryThresholdStore {
        func find(_ code: String) -> InventoryThreshold?
        func save(_ item: InventoryThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryThresholdStore: InventoryThresholdStore {
        var items: [String: InventoryThreshold]
        var order: [String]

        init(items: [String: InventoryThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryThreshold) {
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

        func list() -> [InventoryThreshold] {
            var out: [InventoryThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryThresholdStore() -> any InventoryThresholdStore {
        return MemoryInventoryThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryThresholdStore: InventoryThresholdStore {
        var inner: MemoryInventoryThresholdStore
        var cache: TTLCache<InventoryThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryThresholdStore, cache: TTLCache<InventoryThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryThreshold? {
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

        func save(_ item: InventoryThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryThreshold] {
            return inner.list()
        }
    }

    static func newCachedInventoryThresholdStore(_ inner: MemoryInventoryThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryThresholdStore {
        return CachedInventoryThresholdStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory thresholds. Empty fields match all.
    final class InventoryThresholdQuery {
        var unit: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minScore: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventoryThreshold) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InventoryThreshold]) -> [InventoryThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryThresholds(_ store: any InventoryThresholdStore, query: InventoryThresholdQuery) -> [InventoryThreshold] {
        return query.apply(store.list())
    }
}
