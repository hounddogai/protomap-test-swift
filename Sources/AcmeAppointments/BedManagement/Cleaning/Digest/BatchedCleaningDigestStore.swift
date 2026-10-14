import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps batched cleaning digests by code.
    protocol BatchedCleaningDigestStore {
        func find(_ code: String) -> BatchedCleaningDigest?
        func save(_ item: BatchedCleaningDigest)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedCleaningDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedCleaningDigestStore: BatchedCleaningDigestStore {
        var items: [String: BatchedCleaningDigest]
        var order: [String]

        init(items: [String: BatchedCleaningDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedCleaningDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedCleaningDigest) {
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

        func list() -> [BatchedCleaningDigest] {
            var out: [BatchedCleaningDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedCleaningDigestStore() -> any BatchedCleaningDigestStore {
        return MemoryBatchedCleaningDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedCleaningDigestStore: BatchedCleaningDigestStore {
        var inner: MemoryBatchedCleaningDigestStore
        var cache: TTLCache<BatchedCleaningDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedCleaningDigestStore, cache: TTLCache<BatchedCleaningDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedCleaningDigest? {
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

        func save(_ item: BatchedCleaningDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedCleaningDigest] {
            return inner.list()
        }
    }

    static func newCachedBatchedCleaningDigestStore(_ inner: MemoryBatchedCleaningDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedCleaningDigestStore {
        return CachedBatchedCleaningDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched cleaning digests. Empty fields match all.
    final class BatchedCleaningDigestQuery {
        var label: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedCleaningDigest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [BatchedCleaningDigest]) -> [BatchedCleaningDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedCleaningDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedCleaningDigests(_ store: any BatchedCleaningDigestStore, query: BatchedCleaningDigestQuery) -> [BatchedCleaningDigest] {
        return query.apply(store.list())
    }
}
