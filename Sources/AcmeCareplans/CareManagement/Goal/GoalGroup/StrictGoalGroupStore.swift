import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps strict goal groups by code.
    protocol StrictGoalGroupStore {
        func find(_ code: String) -> StrictGoalGroup?
        func save(_ item: StrictGoalGroup)
        func remove(_ code: String) -> Bool
        func list() -> [StrictGoalGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictGoalGroupStore: StrictGoalGroupStore {
        var items: [String: StrictGoalGroup]
        var order: [String]

        init(items: [String: StrictGoalGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictGoalGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictGoalGroup) {
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

        func list() -> [StrictGoalGroup] {
            var out: [StrictGoalGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictGoalGroupStore() -> any StrictGoalGroupStore {
        return MemoryStrictGoalGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictGoalGroupStore: StrictGoalGroupStore {
        var inner: MemoryStrictGoalGroupStore
        var cache: TTLCache<StrictGoalGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictGoalGroupStore, cache: TTLCache<StrictGoalGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictGoalGroup? {
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

        func save(_ item: StrictGoalGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictGoalGroup] {
            return inner.list()
        }
    }

    static func newCachedStrictGoalGroupStore(_ inner: MemoryStrictGoalGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictGoalGroupStore {
        return CachedStrictGoalGroupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict goal groups. Empty fields match all.
    final class StrictGoalGroupQuery {
        var name: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minScore: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictGoalGroup) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictGoalGroup]) -> [StrictGoalGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictGoalGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictGoalGroups(_ store: any StrictGoalGroupStore, query: StrictGoalGroupQuery) -> [StrictGoalGroup] {
        return query.apply(store.list())
    }
}
