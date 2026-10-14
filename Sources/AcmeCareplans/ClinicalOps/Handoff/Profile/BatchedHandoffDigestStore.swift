import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps batched handoff digests by code.
    protocol BatchedHandoffDigestStore {
        func find(_ code: String) -> BatchedHandoffDigest?
        func save(_ item: BatchedHandoffDigest)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedHandoffDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedHandoffDigestStore: BatchedHandoffDigestStore {
        var items: [String: BatchedHandoffDigest]
        var order: [String]

        init(items: [String: BatchedHandoffDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedHandoffDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedHandoffDigest) {
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

        func list() -> [BatchedHandoffDigest] {
            var out: [BatchedHandoffDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedHandoffDigestStore() -> any BatchedHandoffDigestStore {
        return MemoryBatchedHandoffDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedHandoffDigestStore: BatchedHandoffDigestStore {
        var inner: MemoryBatchedHandoffDigestStore
        var cache: TTLCache<BatchedHandoffDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedHandoffDigestStore, cache: TTLCache<BatchedHandoffDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedHandoffDigest? {
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

        func save(_ item: BatchedHandoffDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedHandoffDigest] {
            return inner.list()
        }
    }

    static func newCachedBatchedHandoffDigestStore(_ inner: MemoryBatchedHandoffDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedHandoffDigestStore {
        return CachedBatchedHandoffDigestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched handoff digests. Empty fields match all.
    final class BatchedHandoffDigestQuery {
        var country: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedHandoffDigest) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedHandoffDigest]) -> [BatchedHandoffDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedHandoffDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedHandoffDigests(_ store: any BatchedHandoffDigestStore, query: BatchedHandoffDigestQuery) -> [BatchedHandoffDigest] {
        return query.apply(store.list())
    }
}
