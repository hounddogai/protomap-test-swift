import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps batched authorization baselines by code.
    protocol BatchedAuthorizationBaselineStore {
        func find(_ code: String) -> BatchedAuthorizationBaseline?
        func save(_ item: BatchedAuthorizationBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedAuthorizationBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedAuthorizationBaselineStore: BatchedAuthorizationBaselineStore {
        var items: [String: BatchedAuthorizationBaseline]
        var order: [String]

        init(items: [String: BatchedAuthorizationBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedAuthorizationBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedAuthorizationBaseline) {
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

        func list() -> [BatchedAuthorizationBaseline] {
            var out: [BatchedAuthorizationBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedAuthorizationBaselineStore() -> any BatchedAuthorizationBaselineStore {
        return MemoryBatchedAuthorizationBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedAuthorizationBaselineStore: BatchedAuthorizationBaselineStore {
        var inner: MemoryBatchedAuthorizationBaselineStore
        var cache: TTLCache<BatchedAuthorizationBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedAuthorizationBaselineStore, cache: TTLCache<BatchedAuthorizationBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedAuthorizationBaseline? {
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

        func save(_ item: BatchedAuthorizationBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedAuthorizationBaseline] {
            return inner.list()
        }
    }

    static func newCachedBatchedAuthorizationBaselineStore(_ inner: MemoryBatchedAuthorizationBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedAuthorizationBaselineStore {
        return CachedBatchedAuthorizationBaselineStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched authorization baselines. Empty fields match all.
    final class BatchedAuthorizationBaselineQuery {
        var ward: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedAuthorizationBaseline) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [BatchedAuthorizationBaseline]) -> [BatchedAuthorizationBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedAuthorizationBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedAuthorizationBaselines(_ store: any BatchedAuthorizationBaselineStore, query: BatchedAuthorizationBaselineQuery) -> [BatchedAuthorizationBaseline] {
        return query.apply(store.list())
    }
}
