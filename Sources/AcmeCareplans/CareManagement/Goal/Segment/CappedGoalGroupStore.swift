import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps capped goal groups by code.
    protocol CappedGoalGroupStore {
        func find(_ code: String) -> CappedGoalGroup?
        func save(_ item: CappedGoalGroup)
        func remove(_ code: String) -> Bool
        func list() -> [CappedGoalGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedGoalGroupStore: CappedGoalGroupStore {
        var items: [String: CappedGoalGroup]
        var order: [String]

        init(items: [String: CappedGoalGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedGoalGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedGoalGroup) {
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

        func list() -> [CappedGoalGroup] {
            var out: [CappedGoalGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedGoalGroupStore() -> any CappedGoalGroupStore {
        return MemoryCappedGoalGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedGoalGroupStore: CappedGoalGroupStore {
        var inner: MemoryCappedGoalGroupStore
        var cache: TTLCache<CappedGoalGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedGoalGroupStore, cache: TTLCache<CappedGoalGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedGoalGroup? {
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

        func save(_ item: CappedGoalGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedGoalGroup] {
            return inner.list()
        }
    }

    static func newCachedCappedGoalGroupStore(_ inner: MemoryCappedGoalGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedGoalGroupStore {
        return CachedCappedGoalGroupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped goal groups. Empty fields match all.
    final class CappedGoalGroupQuery {
        var channel: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedGoalGroup) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedGoalGroup]) -> [CappedGoalGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedGoalGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedGoalGroups(_ store: any CappedGoalGroupStore, query: CappedGoalGroupQuery) -> [CappedGoalGroup] {
        return query.apply(store.list())
    }
}
