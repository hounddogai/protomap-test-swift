import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment batches by code.
    protocol AssessmentBatchStore {
        func find(_ code: String) -> AssessmentBatch?
        func save(_ item: AssessmentBatch)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentBatchStore: AssessmentBatchStore {
        var items: [String: AssessmentBatch]
        var order: [String]

        init(items: [String: AssessmentBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentBatch) {
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

        func list() -> [AssessmentBatch] {
            var out: [AssessmentBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentBatchStore() -> any AssessmentBatchStore {
        return MemoryAssessmentBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentBatchStore: AssessmentBatchStore {
        var inner: MemoryAssessmentBatchStore
        var cache: TTLCache<AssessmentBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentBatchStore, cache: TTLCache<AssessmentBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentBatch? {
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

        func save(_ item: AssessmentBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentBatch] {
            return inner.list()
        }
    }

    static func newCachedAssessmentBatchStore(_ inner: MemoryAssessmentBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentBatchStore {
        return CachedAssessmentBatchStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment batches. Empty fields match all.
    final class AssessmentBatchQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentBatch) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [AssessmentBatch]) -> [AssessmentBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentBatches(_ store: any AssessmentBatchStore, query: AssessmentBatchQuery) -> [AssessmentBatch] {
        return query.apply(store.list())
    }
}
