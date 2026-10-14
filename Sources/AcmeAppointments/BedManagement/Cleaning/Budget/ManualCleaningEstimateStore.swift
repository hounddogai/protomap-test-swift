import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps manual cleaning estimates by code.
    protocol ManualCleaningEstimateStore {
        func find(_ code: String) -> ManualCleaningEstimate?
        func save(_ item: ManualCleaningEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [ManualCleaningEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualCleaningEstimateStore: ManualCleaningEstimateStore {
        var items: [String: ManualCleaningEstimate]
        var order: [String]

        init(items: [String: ManualCleaningEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualCleaningEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualCleaningEstimate) {
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

        func list() -> [ManualCleaningEstimate] {
            var out: [ManualCleaningEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualCleaningEstimateStore() -> any ManualCleaningEstimateStore {
        return MemoryManualCleaningEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualCleaningEstimateStore: ManualCleaningEstimateStore {
        var inner: MemoryManualCleaningEstimateStore
        var cache: TTLCache<ManualCleaningEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualCleaningEstimateStore, cache: TTLCache<ManualCleaningEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualCleaningEstimate? {
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

        func save(_ item: ManualCleaningEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualCleaningEstimate] {
            return inner.list()
        }
    }

    static func newCachedManualCleaningEstimateStore(_ inner: MemoryManualCleaningEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualCleaningEstimateStore {
        return CachedManualCleaningEstimateStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual cleaning estimates. Empty fields match all.
    final class ManualCleaningEstimateQuery {
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

        func matches(_ item: ManualCleaningEstimate) -> Bool {
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

        func apply(_ items: [ManualCleaningEstimate]) -> [ManualCleaningEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualCleaningEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualCleaningEstimates(_ store: any ManualCleaningEstimateStore, query: ManualCleaningEstimateQuery) -> [ManualCleaningEstimate] {
        return query.apply(store.list())
    }
}
