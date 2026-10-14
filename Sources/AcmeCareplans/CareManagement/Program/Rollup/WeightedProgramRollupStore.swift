import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps weighted program rollups by code.
    protocol WeightedProgramRollupStore {
        func find(_ code: String) -> WeightedProgramRollup?
        func save(_ item: WeightedProgramRollup)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedProgramRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedProgramRollupStore: WeightedProgramRollupStore {
        var items: [String: WeightedProgramRollup]
        var order: [String]

        init(items: [String: WeightedProgramRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedProgramRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedProgramRollup) {
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

        func list() -> [WeightedProgramRollup] {
            var out: [WeightedProgramRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedProgramRollupStore() -> any WeightedProgramRollupStore {
        return MemoryWeightedProgramRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedProgramRollupStore: WeightedProgramRollupStore {
        var inner: MemoryWeightedProgramRollupStore
        var cache: TTLCache<WeightedProgramRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedProgramRollupStore, cache: TTLCache<WeightedProgramRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedProgramRollup? {
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

        func save(_ item: WeightedProgramRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedProgramRollup] {
            return inner.list()
        }
    }

    static func newCachedWeightedProgramRollupStore(_ inner: MemoryWeightedProgramRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedProgramRollupStore {
        return CachedWeightedProgramRollupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted program rollups. Empty fields match all.
    final class WeightedProgramRollupQuery {
        var region: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedProgramRollup) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [WeightedProgramRollup]) -> [WeightedProgramRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedProgramRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedProgramRollups(_ store: any WeightedProgramRollupStore, query: WeightedProgramRollupQuery) -> [WeightedProgramRollup] {
        return query.apply(store.list())
    }
}
