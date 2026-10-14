import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps fallback goal groups by code.
    protocol FallbackGoalGroupStore {
        func find(_ code: String) -> FallbackGoalGroup?
        func save(_ item: FallbackGoalGroup)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackGoalGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackGoalGroupStore: FallbackGoalGroupStore {
        var items: [String: FallbackGoalGroup]
        var order: [String]

        init(items: [String: FallbackGoalGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackGoalGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackGoalGroup) {
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

        func list() -> [FallbackGoalGroup] {
            var out: [FallbackGoalGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackGoalGroupStore() -> any FallbackGoalGroupStore {
        return MemoryFallbackGoalGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackGoalGroupStore: FallbackGoalGroupStore {
        var inner: MemoryFallbackGoalGroupStore
        var cache: TTLCache<FallbackGoalGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackGoalGroupStore, cache: TTLCache<FallbackGoalGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackGoalGroup? {
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

        func save(_ item: FallbackGoalGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackGoalGroup] {
            return inner.list()
        }
    }

    static func newCachedFallbackGoalGroupStore(_ inner: MemoryFallbackGoalGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackGoalGroupStore {
        return CachedFallbackGoalGroupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback goal groups. Empty fields match all.
    final class FallbackGoalGroupQuery {
        var title: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackGoalGroup) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackGoalGroup]) -> [FallbackGoalGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackGoalGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackGoalGroups(_ store: any FallbackGoalGroupStore, query: FallbackGoalGroupQuery) -> [FallbackGoalGroup] {
        return query.apply(store.list())
    }
}
