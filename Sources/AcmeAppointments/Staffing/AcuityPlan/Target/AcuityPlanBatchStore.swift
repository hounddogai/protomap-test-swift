import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan batches by code.
    protocol AcuityPlanBatchStore {
        func find(_ code: String) -> AcuityPlanBatch?
        func save(_ item: AcuityPlanBatch)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanBatchStore: AcuityPlanBatchStore {
        var items: [String: AcuityPlanBatch]
        var order: [String]

        init(items: [String: AcuityPlanBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanBatch) {
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

        func list() -> [AcuityPlanBatch] {
            var out: [AcuityPlanBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanBatchStore() -> any AcuityPlanBatchStore {
        return MemoryAcuityPlanBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanBatchStore: AcuityPlanBatchStore {
        var inner: MemoryAcuityPlanBatchStore
        var cache: TTLCache<AcuityPlanBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanBatchStore, cache: TTLCache<AcuityPlanBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanBatch? {
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

        func save(_ item: AcuityPlanBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanBatch] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanBatchStore(_ inner: MemoryAcuityPlanBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanBatchStore {
        return CachedAcuityPlanBatchStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan batches. Empty fields match all.
    final class AcuityPlanBatchQuery {
        var source: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanBatch) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AcuityPlanBatch]) -> [AcuityPlanBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanBatches(_ store: any AcuityPlanBatchStore, query: AcuityPlanBatchQuery) -> [AcuityPlanBatch] {
        return query.apply(store.list())
    }
}
