import AcmePlatform
import Foundation

extension Consent {
    /// Keeps manual witness batches by code.
    protocol ManualWitnessBatchStore {
        func find(_ code: String) -> ManualWitnessBatch?
        func save(_ item: ManualWitnessBatch)
        func remove(_ code: String) -> Bool
        func list() -> [ManualWitnessBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualWitnessBatchStore: ManualWitnessBatchStore {
        var items: [String: ManualWitnessBatch]
        var order: [String]

        init(items: [String: ManualWitnessBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualWitnessBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualWitnessBatch) {
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

        func list() -> [ManualWitnessBatch] {
            var out: [ManualWitnessBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualWitnessBatchStore() -> any ManualWitnessBatchStore {
        return MemoryManualWitnessBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualWitnessBatchStore: ManualWitnessBatchStore {
        var inner: MemoryManualWitnessBatchStore
        var cache: TTLCache<ManualWitnessBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualWitnessBatchStore, cache: TTLCache<ManualWitnessBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualWitnessBatch? {
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

        func save(_ item: ManualWitnessBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualWitnessBatch] {
            return inner.list()
        }
    }

    static func newCachedManualWitnessBatchStore(_ inner: MemoryManualWitnessBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualWitnessBatchStore {
        return CachedManualWitnessBatchStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual witness batches. Empty fields match all.
    final class ManualWitnessBatchQuery {
        var segment: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualWitnessBatch) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [ManualWitnessBatch]) -> [ManualWitnessBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualWitnessBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualWitnessBatches(_ store: any ManualWitnessBatchStore, query: ManualWitnessBatchQuery) -> [ManualWitnessBatch] {
        return query.apply(store.list())
    }
}
