import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps weighted alert overrides by code.
    protocol WeightedAlertOverrideStore {
        func find(_ code: String) -> WeightedAlertOverride?
        func save(_ item: WeightedAlertOverride)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedAlertOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedAlertOverrideStore: WeightedAlertOverrideStore {
        var items: [String: WeightedAlertOverride]
        var order: [String]

        init(items: [String: WeightedAlertOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedAlertOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedAlertOverride) {
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

        func list() -> [WeightedAlertOverride] {
            var out: [WeightedAlertOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedAlertOverrideStore() -> any WeightedAlertOverrideStore {
        return MemoryWeightedAlertOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedAlertOverrideStore: WeightedAlertOverrideStore {
        var inner: MemoryWeightedAlertOverrideStore
        var cache: TTLCache<WeightedAlertOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedAlertOverrideStore, cache: TTLCache<WeightedAlertOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedAlertOverride? {
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

        func save(_ item: WeightedAlertOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedAlertOverride] {
            return inner.list()
        }
    }

    static func newCachedWeightedAlertOverrideStore(_ inner: MemoryWeightedAlertOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedAlertOverrideStore {
        return CachedWeightedAlertOverrideStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted alert overrides. Empty fields match all.
    final class WeightedAlertOverrideQuery {
        var unit: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedAlertOverride) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedAlertOverride]) -> [WeightedAlertOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedAlertOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedAlertOverrides(_ store: any WeightedAlertOverrideStore, query: WeightedAlertOverrideQuery) -> [WeightedAlertOverride] {
        return query.apply(store.list())
    }
}
