import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan batches by code.
    protocol DischargePlanBatchStore {
        func find(_ code: String) -> DischargePlanBatch?
        func save(_ item: DischargePlanBatch)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanBatchStore: DischargePlanBatchStore {
        var items: [String: DischargePlanBatch]
        var order: [String]

        init(items: [String: DischargePlanBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanBatch) {
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

        func list() -> [DischargePlanBatch] {
            var out: [DischargePlanBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanBatchStore() -> any DischargePlanBatchStore {
        return MemoryDischargePlanBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanBatchStore: DischargePlanBatchStore {
        var inner: MemoryDischargePlanBatchStore
        var cache: TTLCache<DischargePlanBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanBatchStore, cache: TTLCache<DischargePlanBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanBatch? {
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

        func save(_ item: DischargePlanBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanBatch] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanBatchStore(_ inner: MemoryDischargePlanBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanBatchStore {
        return CachedDischargePlanBatchStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan batches. Empty fields match all.
    final class DischargePlanBatchQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanBatch) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DischargePlanBatch]) -> [DischargePlanBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanBatches(_ store: any DischargePlanBatchStore, query: DischargePlanBatchQuery) -> [DischargePlanBatch] {
        return query.apply(store.list())
    }
}
