import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps batched goal templates by code.
    protocol BatchedGoalTemplateStore {
        func find(_ code: String) -> BatchedGoalTemplate?
        func save(_ item: BatchedGoalTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedGoalTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedGoalTemplateStore: BatchedGoalTemplateStore {
        var items: [String: BatchedGoalTemplate]
        var order: [String]

        init(items: [String: BatchedGoalTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedGoalTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedGoalTemplate) {
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

        func list() -> [BatchedGoalTemplate] {
            var out: [BatchedGoalTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedGoalTemplateStore() -> any BatchedGoalTemplateStore {
        return MemoryBatchedGoalTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedGoalTemplateStore: BatchedGoalTemplateStore {
        var inner: MemoryBatchedGoalTemplateStore
        var cache: TTLCache<BatchedGoalTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedGoalTemplateStore, cache: TTLCache<BatchedGoalTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedGoalTemplate? {
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

        func save(_ item: BatchedGoalTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedGoalTemplate] {
            return inner.list()
        }
    }

    static func newCachedBatchedGoalTemplateStore(_ inner: MemoryBatchedGoalTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedGoalTemplateStore {
        return CachedBatchedGoalTemplateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched goal templates. Empty fields match all.
    final class BatchedGoalTemplateQuery {
        var name: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedGoalTemplate) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedGoalTemplate]) -> [BatchedGoalTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedGoalTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedGoalTemplates(_ store: any BatchedGoalTemplateStore, query: BatchedGoalTemplateQuery) -> [BatchedGoalTemplate] {
        return query.apply(store.list())
    }
}
