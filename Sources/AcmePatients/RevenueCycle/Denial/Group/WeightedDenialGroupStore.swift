import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps weighted denial groups by code.
    protocol WeightedDenialGroupStore {
        func find(_ code: String) -> WeightedDenialGroup?
        func save(_ item: WeightedDenialGroup)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedDenialGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedDenialGroupStore: WeightedDenialGroupStore {
        var items: [String: WeightedDenialGroup]
        var order: [String]

        init(items: [String: WeightedDenialGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedDenialGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedDenialGroup) {
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

        func list() -> [WeightedDenialGroup] {
            var out: [WeightedDenialGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedDenialGroupStore() -> any WeightedDenialGroupStore {
        return MemoryWeightedDenialGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedDenialGroupStore: WeightedDenialGroupStore {
        var inner: MemoryWeightedDenialGroupStore
        var cache: TTLCache<WeightedDenialGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedDenialGroupStore, cache: TTLCache<WeightedDenialGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedDenialGroup? {
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

        func save(_ item: WeightedDenialGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedDenialGroup] {
            return inner.list()
        }
    }

    static func newCachedWeightedDenialGroupStore(_ inner: MemoryWeightedDenialGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedDenialGroupStore {
        return CachedWeightedDenialGroupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted denial groups. Empty fields match all.
    final class WeightedDenialGroupQuery {
        var facility: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedDenialGroup) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [WeightedDenialGroup]) -> [WeightedDenialGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedDenialGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedDenialGroups(_ store: any WeightedDenialGroupStore, query: WeightedDenialGroupQuery) -> [WeightedDenialGroup] {
        return query.apply(store.list())
    }
}
