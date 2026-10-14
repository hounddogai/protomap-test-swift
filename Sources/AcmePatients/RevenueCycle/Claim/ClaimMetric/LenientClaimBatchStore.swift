import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps lenient claim batches by code.
    protocol LenientClaimBatchStore {
        func find(_ code: String) -> LenientClaimBatch?
        func save(_ item: LenientClaimBatch)
        func remove(_ code: String) -> Bool
        func list() -> [LenientClaimBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientClaimBatchStore: LenientClaimBatchStore {
        var items: [String: LenientClaimBatch]
        var order: [String]

        init(items: [String: LenientClaimBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientClaimBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientClaimBatch) {
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

        func list() -> [LenientClaimBatch] {
            var out: [LenientClaimBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientClaimBatchStore() -> any LenientClaimBatchStore {
        return MemoryLenientClaimBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientClaimBatchStore: LenientClaimBatchStore {
        var inner: MemoryLenientClaimBatchStore
        var cache: TTLCache<LenientClaimBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientClaimBatchStore, cache: TTLCache<LenientClaimBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientClaimBatch? {
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

        func save(_ item: LenientClaimBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientClaimBatch] {
            return inner.list()
        }
    }

    static func newCachedLenientClaimBatchStore(_ inner: MemoryLenientClaimBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientClaimBatchStore {
        return CachedLenientClaimBatchStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient claim batches. Empty fields match all.
    final class LenientClaimBatchQuery {
        var title: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVersion: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientClaimBatch) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientClaimBatch]) -> [LenientClaimBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientClaimBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientClaimBatches(_ store: any LenientClaimBatchStore, query: LenientClaimBatchQuery) -> [LenientClaimBatch] {
        return query.apply(store.list())
    }
}
