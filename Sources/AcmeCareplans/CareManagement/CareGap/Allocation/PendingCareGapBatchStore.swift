import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps pending care gap batches by code.
    protocol PendingCareGapBatchStore {
        func find(_ code: String) -> PendingCareGapBatch?
        func save(_ item: PendingCareGapBatch)
        func remove(_ code: String) -> Bool
        func list() -> [PendingCareGapBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingCareGapBatchStore: PendingCareGapBatchStore {
        var items: [String: PendingCareGapBatch]
        var order: [String]

        init(items: [String: PendingCareGapBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingCareGapBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingCareGapBatch) {
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

        func list() -> [PendingCareGapBatch] {
            var out: [PendingCareGapBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingCareGapBatchStore() -> any PendingCareGapBatchStore {
        return MemoryPendingCareGapBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingCareGapBatchStore: PendingCareGapBatchStore {
        var inner: MemoryPendingCareGapBatchStore
        var cache: TTLCache<PendingCareGapBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingCareGapBatchStore, cache: TTLCache<PendingCareGapBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingCareGapBatch? {
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

        func save(_ item: PendingCareGapBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingCareGapBatch] {
            return inner.list()
        }
    }

    static func newCachedPendingCareGapBatchStore(_ inner: MemoryPendingCareGapBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingCareGapBatchStore {
        return CachedPendingCareGapBatchStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending care gap batches. Empty fields match all.
    final class PendingCareGapBatchQuery {
        var label: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingCareGapBatch) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [PendingCareGapBatch]) -> [PendingCareGapBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingCareGapBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingCareGapBatches(_ store: any PendingCareGapBatchStore, query: PendingCareGapBatchQuery) -> [PendingCareGapBatch] {
        return query.apply(store.list())
    }
}
