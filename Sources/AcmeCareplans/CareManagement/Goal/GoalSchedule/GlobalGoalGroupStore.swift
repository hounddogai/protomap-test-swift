import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps global goal groups by code.
    protocol GlobalGoalGroupStore {
        func find(_ code: String) -> GlobalGoalGroup?
        func save(_ item: GlobalGoalGroup)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalGoalGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalGoalGroupStore: GlobalGoalGroupStore {
        var items: [String: GlobalGoalGroup]
        var order: [String]

        init(items: [String: GlobalGoalGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalGoalGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalGoalGroup) {
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

        func list() -> [GlobalGoalGroup] {
            var out: [GlobalGoalGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalGoalGroupStore() -> any GlobalGoalGroupStore {
        return MemoryGlobalGoalGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalGoalGroupStore: GlobalGoalGroupStore {
        var inner: MemoryGlobalGoalGroupStore
        var cache: TTLCache<GlobalGoalGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalGoalGroupStore, cache: TTLCache<GlobalGoalGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalGoalGroup? {
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

        func save(_ item: GlobalGoalGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalGoalGroup] {
            return inner.list()
        }
    }

    static func newCachedGlobalGoalGroupStore(_ inner: MemoryGlobalGoalGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalGoalGroupStore {
        return CachedGlobalGoalGroupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global goal groups. Empty fields match all.
    final class GlobalGoalGroupQuery {
        var source: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minRate: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalGoalGroup) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [GlobalGoalGroup]) -> [GlobalGoalGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalGoalGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalGoalGroups(_ store: any GlobalGoalGroupStore, query: GlobalGoalGroupQuery) -> [GlobalGoalGroup] {
        return query.apply(store.list())
    }
}
