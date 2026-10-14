import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal claims by code.
    protocol GoalClaimStore {
        func find(_ code: String) -> GoalClaim?
        func save(_ item: GoalClaim)
        func remove(_ code: String) -> Bool
        func list() -> [GoalClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalClaimStore: GoalClaimStore {
        var items: [String: GoalClaim]
        var order: [String]

        init(items: [String: GoalClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalClaim) {
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

        func list() -> [GoalClaim] {
            var out: [GoalClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalClaimStore() -> any GoalClaimStore {
        return MemoryGoalClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalClaimStore: GoalClaimStore {
        var inner: MemoryGoalClaimStore
        var cache: TTLCache<GoalClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalClaimStore, cache: TTLCache<GoalClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalClaim? {
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

        func save(_ item: GoalClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalClaim] {
            return inner.list()
        }
    }

    static func newCachedGoalClaimStore(_ inner: MemoryGoalClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalClaimStore {
        return CachedGoalClaimStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal claims. Empty fields match all.
    final class GoalClaimQuery {
        var name: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalClaim) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GoalClaim]) -> [GoalClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalClaims(_ store: any GoalClaimStore, query: GoalClaimQuery) -> [GoalClaim] {
        return query.apply(store.list())
    }
}
