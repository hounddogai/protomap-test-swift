import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps batched remittance targets by code.
    protocol BatchedRemittanceTargetStore {
        func find(_ code: String) -> BatchedRemittanceTarget?
        func save(_ item: BatchedRemittanceTarget)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedRemittanceTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedRemittanceTargetStore: BatchedRemittanceTargetStore {
        var items: [String: BatchedRemittanceTarget]
        var order: [String]

        init(items: [String: BatchedRemittanceTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedRemittanceTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedRemittanceTarget) {
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

        func list() -> [BatchedRemittanceTarget] {
            var out: [BatchedRemittanceTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedRemittanceTargetStore() -> any BatchedRemittanceTargetStore {
        return MemoryBatchedRemittanceTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedRemittanceTargetStore: BatchedRemittanceTargetStore {
        var inner: MemoryBatchedRemittanceTargetStore
        var cache: TTLCache<BatchedRemittanceTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedRemittanceTargetStore, cache: TTLCache<BatchedRemittanceTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedRemittanceTarget? {
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

        func save(_ item: BatchedRemittanceTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedRemittanceTarget] {
            return inner.list()
        }
    }

    static func newCachedBatchedRemittanceTargetStore(_ inner: MemoryBatchedRemittanceTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedRemittanceTargetStore {
        return CachedBatchedRemittanceTargetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched remittance targets. Empty fields match all.
    final class BatchedRemittanceTargetQuery {
        var locale: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedRemittanceTarget) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [BatchedRemittanceTarget]) -> [BatchedRemittanceTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedRemittanceTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedRemittanceTargets(_ store: any BatchedRemittanceTargetStore, query: BatchedRemittanceTargetQuery) -> [BatchedRemittanceTarget] {
        return query.apply(store.list())
    }
}
