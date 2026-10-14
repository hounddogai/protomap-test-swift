import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps weighted claim groups by code.
    protocol WeightedClaimGroupStore {
        func find(_ code: String) -> WeightedClaimGroup?
        func save(_ item: WeightedClaimGroup)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedClaimGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedClaimGroupStore: WeightedClaimGroupStore {
        var items: [String: WeightedClaimGroup]
        var order: [String]

        init(items: [String: WeightedClaimGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedClaimGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedClaimGroup) {
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

        func list() -> [WeightedClaimGroup] {
            var out: [WeightedClaimGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedClaimGroupStore() -> any WeightedClaimGroupStore {
        return MemoryWeightedClaimGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedClaimGroupStore: WeightedClaimGroupStore {
        var inner: MemoryWeightedClaimGroupStore
        var cache: TTLCache<WeightedClaimGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedClaimGroupStore, cache: TTLCache<WeightedClaimGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedClaimGroup? {
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

        func save(_ item: WeightedClaimGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedClaimGroup] {
            return inner.list()
        }
    }

    static func newCachedWeightedClaimGroupStore(_ inner: MemoryWeightedClaimGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedClaimGroupStore {
        return CachedWeightedClaimGroupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted claim groups. Empty fields match all.
    final class WeightedClaimGroupQuery {
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

        func matches(_ item: WeightedClaimGroup) -> Bool {
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

        func apply(_ items: [WeightedClaimGroup]) -> [WeightedClaimGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedClaimGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedClaimGroups(_ store: any WeightedClaimGroupStore, query: WeightedClaimGroupQuery) -> [WeightedClaimGroup] {
        return query.apply(store.list())
    }
}
