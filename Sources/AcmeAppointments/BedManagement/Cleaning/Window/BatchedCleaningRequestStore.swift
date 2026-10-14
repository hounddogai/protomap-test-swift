import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps batched cleaning requests by code.
    protocol BatchedCleaningRequestStore {
        func find(_ code: String) -> BatchedCleaningRequest?
        func save(_ item: BatchedCleaningRequest)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedCleaningRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedCleaningRequestStore: BatchedCleaningRequestStore {
        var items: [String: BatchedCleaningRequest]
        var order: [String]

        init(items: [String: BatchedCleaningRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedCleaningRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedCleaningRequest) {
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

        func list() -> [BatchedCleaningRequest] {
            var out: [BatchedCleaningRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedCleaningRequestStore() -> any BatchedCleaningRequestStore {
        return MemoryBatchedCleaningRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedCleaningRequestStore: BatchedCleaningRequestStore {
        var inner: MemoryBatchedCleaningRequestStore
        var cache: TTLCache<BatchedCleaningRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedCleaningRequestStore, cache: TTLCache<BatchedCleaningRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedCleaningRequest? {
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

        func save(_ item: BatchedCleaningRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedCleaningRequest] {
            return inner.list()
        }
    }

    static func newCachedBatchedCleaningRequestStore(_ inner: MemoryBatchedCleaningRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedCleaningRequestStore {
        return CachedBatchedCleaningRequestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched cleaning requests. Empty fields match all.
    final class BatchedCleaningRequestQuery {
        var region: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedCleaningRequest) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedCleaningRequest]) -> [BatchedCleaningRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedCleaningRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedCleaningRequests(_ store: any BatchedCleaningRequestStore, query: BatchedCleaningRequestQuery) -> [BatchedCleaningRequest] {
        return query.apply(store.list())
    }
}
