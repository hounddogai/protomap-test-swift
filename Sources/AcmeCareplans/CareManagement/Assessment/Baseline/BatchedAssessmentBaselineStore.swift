import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps batched assessment baselines by code.
    protocol BatchedAssessmentBaselineStore {
        func find(_ code: String) -> BatchedAssessmentBaseline?
        func save(_ item: BatchedAssessmentBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedAssessmentBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedAssessmentBaselineStore: BatchedAssessmentBaselineStore {
        var items: [String: BatchedAssessmentBaseline]
        var order: [String]

        init(items: [String: BatchedAssessmentBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedAssessmentBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedAssessmentBaseline) {
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

        func list() -> [BatchedAssessmentBaseline] {
            var out: [BatchedAssessmentBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedAssessmentBaselineStore() -> any BatchedAssessmentBaselineStore {
        return MemoryBatchedAssessmentBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedAssessmentBaselineStore: BatchedAssessmentBaselineStore {
        var inner: MemoryBatchedAssessmentBaselineStore
        var cache: TTLCache<BatchedAssessmentBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedAssessmentBaselineStore, cache: TTLCache<BatchedAssessmentBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedAssessmentBaseline? {
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

        func save(_ item: BatchedAssessmentBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedAssessmentBaseline] {
            return inner.list()
        }
    }

    static func newCachedBatchedAssessmentBaselineStore(_ inner: MemoryBatchedAssessmentBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedAssessmentBaselineStore {
        return CachedBatchedAssessmentBaselineStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched assessment baselines. Empty fields match all.
    final class BatchedAssessmentBaselineQuery {
        var unit: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedAssessmentBaseline) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedAssessmentBaseline]) -> [BatchedAssessmentBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedAssessmentBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedAssessmentBaselines(_ store: any BatchedAssessmentBaselineStore, query: BatchedAssessmentBaselineQuery) -> [BatchedAssessmentBaseline] {
        return query.apply(store.list())
    }
}
