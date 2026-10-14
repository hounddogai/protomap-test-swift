import AcmePlatform
import Foundation

extension Consent {
    /// Keeps legacy witness groups by code.
    protocol LegacyWitnessGroupStore {
        func find(_ code: String) -> LegacyWitnessGroup?
        func save(_ item: LegacyWitnessGroup)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyWitnessGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyWitnessGroupStore: LegacyWitnessGroupStore {
        var items: [String: LegacyWitnessGroup]
        var order: [String]

        init(items: [String: LegacyWitnessGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyWitnessGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyWitnessGroup) {
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

        func list() -> [LegacyWitnessGroup] {
            var out: [LegacyWitnessGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyWitnessGroupStore() -> any LegacyWitnessGroupStore {
        return MemoryLegacyWitnessGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyWitnessGroupStore: LegacyWitnessGroupStore {
        var inner: MemoryLegacyWitnessGroupStore
        var cache: TTLCache<LegacyWitnessGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyWitnessGroupStore, cache: TTLCache<LegacyWitnessGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyWitnessGroup? {
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

        func save(_ item: LegacyWitnessGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyWitnessGroup] {
            return inner.list()
        }
    }

    static func newCachedLegacyWitnessGroupStore(_ inner: MemoryLegacyWitnessGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyWitnessGroupStore {
        return CachedLegacyWitnessGroupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy witness groups. Empty fields match all.
    final class LegacyWitnessGroupQuery {
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

        func matches(_ item: LegacyWitnessGroup) -> Bool {
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

        func apply(_ items: [LegacyWitnessGroup]) -> [LegacyWitnessGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyWitnessGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyWitnessGroups(_ store: any LegacyWitnessGroupStore, query: LegacyWitnessGroupQuery) -> [LegacyWitnessGroup] {
        return query.apply(store.list())
    }
}
