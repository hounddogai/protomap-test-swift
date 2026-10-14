import AcmePlatform
import Foundation

extension Consent {
    /// Keeps weighted witness rollups by code.
    protocol WeightedWitnessRollupStore {
        func find(_ code: String) -> WeightedWitnessRollup?
        func save(_ item: WeightedWitnessRollup)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedWitnessRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedWitnessRollupStore: WeightedWitnessRollupStore {
        var items: [String: WeightedWitnessRollup]
        var order: [String]

        init(items: [String: WeightedWitnessRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedWitnessRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedWitnessRollup) {
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

        func list() -> [WeightedWitnessRollup] {
            var out: [WeightedWitnessRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedWitnessRollupStore() -> any WeightedWitnessRollupStore {
        return MemoryWeightedWitnessRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedWitnessRollupStore: WeightedWitnessRollupStore {
        var inner: MemoryWeightedWitnessRollupStore
        var cache: TTLCache<WeightedWitnessRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedWitnessRollupStore, cache: TTLCache<WeightedWitnessRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedWitnessRollup? {
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

        func save(_ item: WeightedWitnessRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedWitnessRollup] {
            return inner.list()
        }
    }

    static func newCachedWeightedWitnessRollupStore(_ inner: MemoryWeightedWitnessRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedWitnessRollupStore {
        return CachedWeightedWitnessRollupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted witness rollups. Empty fields match all.
    final class WeightedWitnessRollupQuery {
        var category: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedWitnessRollup) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedWitnessRollup]) -> [WeightedWitnessRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedWitnessRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedWitnessRollups(_ store: any WeightedWitnessRollupStore, query: WeightedWitnessRollupQuery) -> [WeightedWitnessRollup] {
        return query.apply(store.list())
    }
}
