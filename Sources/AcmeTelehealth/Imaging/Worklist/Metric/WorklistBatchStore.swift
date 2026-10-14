import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist batches by code.
    protocol WorklistBatchStore {
        func find(_ code: String) -> WorklistBatch?
        func save(_ item: WorklistBatch)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistBatchStore: WorklistBatchStore {
        var items: [String: WorklistBatch]
        var order: [String]

        init(items: [String: WorklistBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistBatch) {
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

        func list() -> [WorklistBatch] {
            var out: [WorklistBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistBatchStore() -> any WorklistBatchStore {
        return MemoryWorklistBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistBatchStore: WorklistBatchStore {
        var inner: MemoryWorklistBatchStore
        var cache: TTLCache<WorklistBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistBatchStore, cache: TTLCache<WorklistBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistBatch? {
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

        func save(_ item: WorklistBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistBatch] {
            return inner.list()
        }
    }

    static func newCachedWorklistBatchStore(_ inner: MemoryWorklistBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistBatchStore {
        return CachedWorklistBatchStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist batches. Empty fields match all.
    final class WorklistBatchQuery {
        var country: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minBudget: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistBatch) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WorklistBatch]) -> [WorklistBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistBatches(_ store: any WorklistBatchStore, query: WorklistBatchQuery) -> [WorklistBatch] {
        return query.apply(store.list())
    }
}
