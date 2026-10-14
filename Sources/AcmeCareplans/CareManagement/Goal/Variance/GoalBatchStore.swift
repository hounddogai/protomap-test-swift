import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal batches by code.
    protocol GoalBatchStore {
        func find(_ code: String) -> GoalBatch?
        func save(_ item: GoalBatch)
        func remove(_ code: String) -> Bool
        func list() -> [GoalBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalBatchStore: GoalBatchStore {
        var items: [String: GoalBatch]
        var order: [String]

        init(items: [String: GoalBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalBatch) {
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

        func list() -> [GoalBatch] {
            var out: [GoalBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalBatchStore() -> any GoalBatchStore {
        return MemoryGoalBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalBatchStore: GoalBatchStore {
        var inner: MemoryGoalBatchStore
        var cache: TTLCache<GoalBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalBatchStore, cache: TTLCache<GoalBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalBatch? {
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

        func save(_ item: GoalBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalBatch] {
            return inner.list()
        }
    }

    static func newCachedGoalBatchStore(_ inner: MemoryGoalBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalBatchStore {
        return CachedGoalBatchStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal batches. Empty fields match all.
    final class GoalBatchQuery {
        var title: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalBatch) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [GoalBatch]) -> [GoalBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalBatches(_ store: any GoalBatchStore, query: GoalBatchQuery) -> [GoalBatch] {
        return query.apply(store.list())
    }
}
