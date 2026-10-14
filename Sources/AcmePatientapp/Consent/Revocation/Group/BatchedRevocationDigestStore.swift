import AcmePlatform
import Foundation

extension Consent {
    /// Keeps batched revocation digests by code.
    protocol BatchedRevocationDigestStore {
        func find(_ code: String) -> BatchedRevocationDigest?
        func save(_ item: BatchedRevocationDigest)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedRevocationDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedRevocationDigestStore: BatchedRevocationDigestStore {
        var items: [String: BatchedRevocationDigest]
        var order: [String]

        init(items: [String: BatchedRevocationDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedRevocationDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedRevocationDigest) {
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

        func list() -> [BatchedRevocationDigest] {
            var out: [BatchedRevocationDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedRevocationDigestStore() -> any BatchedRevocationDigestStore {
        return MemoryBatchedRevocationDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedRevocationDigestStore: BatchedRevocationDigestStore {
        var inner: MemoryBatchedRevocationDigestStore
        var cache: TTLCache<BatchedRevocationDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedRevocationDigestStore, cache: TTLCache<BatchedRevocationDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedRevocationDigest? {
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

        func save(_ item: BatchedRevocationDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedRevocationDigest] {
            return inner.list()
        }
    }

    static func newCachedBatchedRevocationDigestStore(_ inner: MemoryBatchedRevocationDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedRevocationDigestStore {
        return CachedBatchedRevocationDigestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched revocation digests. Empty fields match all.
    final class BatchedRevocationDigestQuery {
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

        func matches(_ item: BatchedRevocationDigest) -> Bool {
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

        func apply(_ items: [BatchedRevocationDigest]) -> [BatchedRevocationDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedRevocationDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedRevocationDigests(_ store: any BatchedRevocationDigestStore, query: BatchedRevocationDigestQuery) -> [BatchedRevocationDigest] {
        return query.apply(store.list())
    }
}
