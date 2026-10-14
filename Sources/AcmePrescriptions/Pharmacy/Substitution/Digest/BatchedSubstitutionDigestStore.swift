import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps batched substitution digests by code.
    protocol BatchedSubstitutionDigestStore {
        func find(_ code: String) -> BatchedSubstitutionDigest?
        func save(_ item: BatchedSubstitutionDigest)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedSubstitutionDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedSubstitutionDigestStore: BatchedSubstitutionDigestStore {
        var items: [String: BatchedSubstitutionDigest]
        var order: [String]

        init(items: [String: BatchedSubstitutionDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedSubstitutionDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedSubstitutionDigest) {
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

        func list() -> [BatchedSubstitutionDigest] {
            var out: [BatchedSubstitutionDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedSubstitutionDigestStore() -> any BatchedSubstitutionDigestStore {
        return MemoryBatchedSubstitutionDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedSubstitutionDigestStore: BatchedSubstitutionDigestStore {
        var inner: MemoryBatchedSubstitutionDigestStore
        var cache: TTLCache<BatchedSubstitutionDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedSubstitutionDigestStore, cache: TTLCache<BatchedSubstitutionDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedSubstitutionDigest? {
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

        func save(_ item: BatchedSubstitutionDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedSubstitutionDigest] {
            return inner.list()
        }
    }

    static func newCachedBatchedSubstitutionDigestStore(_ inner: MemoryBatchedSubstitutionDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedSubstitutionDigestStore {
        return CachedBatchedSubstitutionDigestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched substitution digests. Empty fields match all.
    final class BatchedSubstitutionDigestQuery {
        var ward: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedSubstitutionDigest) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedSubstitutionDigest]) -> [BatchedSubstitutionDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedSubstitutionDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedSubstitutionDigests(_ store: any BatchedSubstitutionDigestStore, query: BatchedSubstitutionDigestQuery) -> [BatchedSubstitutionDigest] {
        return query.apply(store.list())
    }
}
