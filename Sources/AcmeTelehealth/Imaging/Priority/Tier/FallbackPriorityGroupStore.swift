import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps fallback priority groups by code.
    protocol FallbackPriorityGroupStore {
        func find(_ code: String) -> FallbackPriorityGroup?
        func save(_ item: FallbackPriorityGroup)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackPriorityGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackPriorityGroupStore: FallbackPriorityGroupStore {
        var items: [String: FallbackPriorityGroup]
        var order: [String]

        init(items: [String: FallbackPriorityGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackPriorityGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackPriorityGroup) {
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

        func list() -> [FallbackPriorityGroup] {
            var out: [FallbackPriorityGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackPriorityGroupStore() -> any FallbackPriorityGroupStore {
        return MemoryFallbackPriorityGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackPriorityGroupStore: FallbackPriorityGroupStore {
        var inner: MemoryFallbackPriorityGroupStore
        var cache: TTLCache<FallbackPriorityGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackPriorityGroupStore, cache: TTLCache<FallbackPriorityGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackPriorityGroup? {
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

        func save(_ item: FallbackPriorityGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackPriorityGroup] {
            return inner.list()
        }
    }

    static func newCachedFallbackPriorityGroupStore(_ inner: MemoryFallbackPriorityGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackPriorityGroupStore {
        return CachedFallbackPriorityGroupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback priority groups. Empty fields match all.
    final class FallbackPriorityGroupQuery {
        var category: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minCost: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackPriorityGroup) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [FallbackPriorityGroup]) -> [FallbackPriorityGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackPriorityGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackPriorityGroups(_ store: any FallbackPriorityGroupStore, query: FallbackPriorityGroupQuery) -> [FallbackPriorityGroup] {
        return query.apply(store.list())
    }
}
