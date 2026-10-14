import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal requests by code.
    protocol GoalRequestStore {
        func find(_ code: String) -> GoalRequest?
        func save(_ item: GoalRequest)
        func remove(_ code: String) -> Bool
        func list() -> [GoalRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalRequestStore: GoalRequestStore {
        var items: [String: GoalRequest]
        var order: [String]

        init(items: [String: GoalRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalRequest) {
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

        func list() -> [GoalRequest] {
            var out: [GoalRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalRequestStore() -> any GoalRequestStore {
        return MemoryGoalRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalRequestStore: GoalRequestStore {
        var inner: MemoryGoalRequestStore
        var cache: TTLCache<GoalRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalRequestStore, cache: TTLCache<GoalRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalRequest? {
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

        func save(_ item: GoalRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalRequest] {
            return inner.list()
        }
    }

    static func newCachedGoalRequestStore(_ inner: MemoryGoalRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalRequestStore {
        return CachedGoalRequestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal requests. Empty fields match all.
    final class GoalRequestQuery {
        var region: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalRequest) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [GoalRequest]) -> [GoalRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalRequests(_ store: any GoalRequestStore, query: GoalRequestQuery) -> [GoalRequest] {
        return query.apply(store.list())
    }
}
