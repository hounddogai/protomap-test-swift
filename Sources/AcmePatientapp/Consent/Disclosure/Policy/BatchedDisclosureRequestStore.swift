import AcmePlatform
import Foundation

extension Consent {
    /// Keeps batched disclosure requests by code.
    protocol BatchedDisclosureRequestStore {
        func find(_ code: String) -> BatchedDisclosureRequest?
        func save(_ item: BatchedDisclosureRequest)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedDisclosureRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedDisclosureRequestStore: BatchedDisclosureRequestStore {
        var items: [String: BatchedDisclosureRequest]
        var order: [String]

        init(items: [String: BatchedDisclosureRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedDisclosureRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedDisclosureRequest) {
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

        func list() -> [BatchedDisclosureRequest] {
            var out: [BatchedDisclosureRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedDisclosureRequestStore() -> any BatchedDisclosureRequestStore {
        return MemoryBatchedDisclosureRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedDisclosureRequestStore: BatchedDisclosureRequestStore {
        var inner: MemoryBatchedDisclosureRequestStore
        var cache: TTLCache<BatchedDisclosureRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedDisclosureRequestStore, cache: TTLCache<BatchedDisclosureRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedDisclosureRequest? {
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

        func save(_ item: BatchedDisclosureRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedDisclosureRequest] {
            return inner.list()
        }
    }

    static func newCachedBatchedDisclosureRequestStore(_ inner: MemoryBatchedDisclosureRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedDisclosureRequestStore {
        return CachedBatchedDisclosureRequestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched disclosure requests. Empty fields match all.
    final class BatchedDisclosureRequestQuery {
        var segment: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedDisclosureRequest) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedDisclosureRequest]) -> [BatchedDisclosureRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedDisclosureRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedDisclosureRequests(_ store: any BatchedDisclosureRequestStore, query: BatchedDisclosureRequestQuery) -> [BatchedDisclosureRequest] {
        return query.apply(store.list())
    }
}
