import AcmePlatform
import Foundation

extension Labs {
    /// Keeps weighted specimen cycles by code.
    protocol WeightedSpecimenCycleStore {
        func find(_ code: String) -> WeightedSpecimenCycle?
        func save(_ item: WeightedSpecimenCycle)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedSpecimenCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedSpecimenCycleStore: WeightedSpecimenCycleStore {
        var items: [String: WeightedSpecimenCycle]
        var order: [String]

        init(items: [String: WeightedSpecimenCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedSpecimenCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedSpecimenCycle) {
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

        func list() -> [WeightedSpecimenCycle] {
            var out: [WeightedSpecimenCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedSpecimenCycleStore() -> any WeightedSpecimenCycleStore {
        return MemoryWeightedSpecimenCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedSpecimenCycleStore: WeightedSpecimenCycleStore {
        var inner: MemoryWeightedSpecimenCycleStore
        var cache: TTLCache<WeightedSpecimenCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedSpecimenCycleStore, cache: TTLCache<WeightedSpecimenCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedSpecimenCycle? {
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

        func save(_ item: WeightedSpecimenCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedSpecimenCycle] {
            return inner.list()
        }
    }

    static func newCachedWeightedSpecimenCycleStore(_ inner: MemoryWeightedSpecimenCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedSpecimenCycleStore {
        return CachedWeightedSpecimenCycleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted specimen cycles. Empty fields match all.
    final class WeightedSpecimenCycleQuery {
        var ward: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minRate: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedSpecimenCycle) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedSpecimenCycle]) -> [WeightedSpecimenCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedSpecimenCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedSpecimenCycles(_ store: any WeightedSpecimenCycleStore, query: WeightedSpecimenCycleQuery) -> [WeightedSpecimenCycle] {
        return query.apply(store.list())
    }
}
