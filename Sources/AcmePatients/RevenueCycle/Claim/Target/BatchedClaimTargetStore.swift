import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps batched claim targets by code.
    protocol BatchedClaimTargetStore {
        func find(_ code: String) -> BatchedClaimTarget?
        func save(_ item: BatchedClaimTarget)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedClaimTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedClaimTargetStore: BatchedClaimTargetStore {
        var items: [String: BatchedClaimTarget]
        var order: [String]

        init(items: [String: BatchedClaimTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedClaimTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedClaimTarget) {
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

        func list() -> [BatchedClaimTarget] {
            var out: [BatchedClaimTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedClaimTargetStore() -> any BatchedClaimTargetStore {
        return MemoryBatchedClaimTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedClaimTargetStore: BatchedClaimTargetStore {
        var inner: MemoryBatchedClaimTargetStore
        var cache: TTLCache<BatchedClaimTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedClaimTargetStore, cache: TTLCache<BatchedClaimTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedClaimTarget? {
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

        func save(_ item: BatchedClaimTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedClaimTarget] {
            return inner.list()
        }
    }

    static func newCachedBatchedClaimTargetStore(_ inner: MemoryBatchedClaimTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedClaimTargetStore {
        return CachedBatchedClaimTargetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched claim targets. Empty fields match all.
    final class BatchedClaimTargetQuery {
        var locale: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedClaimTarget) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedClaimTarget]) -> [BatchedClaimTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedClaimTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedClaimTargets(_ store: any BatchedClaimTargetStore, query: BatchedClaimTargetQuery) -> [BatchedClaimTarget] {
        return query.apply(store.list())
    }
}
