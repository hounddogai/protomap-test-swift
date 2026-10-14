import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps weighted dispense mappings by code.
    protocol WeightedDispenseMappingStore {
        func find(_ code: String) -> WeightedDispenseMapping?
        func save(_ item: WeightedDispenseMapping)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedDispenseMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedDispenseMappingStore: WeightedDispenseMappingStore {
        var items: [String: WeightedDispenseMapping]
        var order: [String]

        init(items: [String: WeightedDispenseMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedDispenseMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedDispenseMapping) {
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

        func list() -> [WeightedDispenseMapping] {
            var out: [WeightedDispenseMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedDispenseMappingStore() -> any WeightedDispenseMappingStore {
        return MemoryWeightedDispenseMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedDispenseMappingStore: WeightedDispenseMappingStore {
        var inner: MemoryWeightedDispenseMappingStore
        var cache: TTLCache<WeightedDispenseMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedDispenseMappingStore, cache: TTLCache<WeightedDispenseMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedDispenseMapping? {
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

        func save(_ item: WeightedDispenseMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedDispenseMapping] {
            return inner.list()
        }
    }

    static func newCachedWeightedDispenseMappingStore(_ inner: MemoryWeightedDispenseMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedDispenseMappingStore {
        return CachedWeightedDispenseMappingStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted dispense mappings. Empty fields match all.
    final class WeightedDispenseMappingQuery {
        var label: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minBudget: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedDispenseMapping) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [WeightedDispenseMapping]) -> [WeightedDispenseMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedDispenseMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedDispenseMappings(_ store: any WeightedDispenseMappingStore, query: WeightedDispenseMappingQuery) -> [WeightedDispenseMapping] {
        return query.apply(store.list())
    }
}
