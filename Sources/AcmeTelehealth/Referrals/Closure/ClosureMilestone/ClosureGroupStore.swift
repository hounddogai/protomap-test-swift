import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure groups by code.
    protocol ClosureGroupStore {
        func find(_ code: String) -> ClosureGroup?
        func save(_ item: ClosureGroup)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureGroupStore: ClosureGroupStore {
        var items: [String: ClosureGroup]
        var order: [String]

        init(items: [String: ClosureGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureGroup) {
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

        func list() -> [ClosureGroup] {
            var out: [ClosureGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureGroupStore() -> any ClosureGroupStore {
        return MemoryClosureGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureGroupStore: ClosureGroupStore {
        var inner: MemoryClosureGroupStore
        var cache: TTLCache<ClosureGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureGroupStore, cache: TTLCache<ClosureGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureGroup? {
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

        func save(_ item: ClosureGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureGroup] {
            return inner.list()
        }
    }

    static func newCachedClosureGroupStore(_ inner: MemoryClosureGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureGroupStore {
        return CachedClosureGroupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure groups. Empty fields match all.
    final class ClosureGroupQuery {
        var facility: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minCost: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosureGroup) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClosureGroup]) -> [ClosureGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureGroups(_ store: any ClosureGroupStore, query: ClosureGroupQuery) -> [ClosureGroup] {
        return query.apply(store.list())
    }
}
