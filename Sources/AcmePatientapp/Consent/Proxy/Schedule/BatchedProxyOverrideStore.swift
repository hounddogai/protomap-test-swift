import AcmePlatform
import Foundation

extension Consent {
    /// Keeps batched proxy overrides by code.
    protocol BatchedProxyOverrideStore {
        func find(_ code: String) -> BatchedProxyOverride?
        func save(_ item: BatchedProxyOverride)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedProxyOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedProxyOverrideStore: BatchedProxyOverrideStore {
        var items: [String: BatchedProxyOverride]
        var order: [String]

        init(items: [String: BatchedProxyOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedProxyOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedProxyOverride) {
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

        func list() -> [BatchedProxyOverride] {
            var out: [BatchedProxyOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedProxyOverrideStore() -> any BatchedProxyOverrideStore {
        return MemoryBatchedProxyOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedProxyOverrideStore: BatchedProxyOverrideStore {
        var inner: MemoryBatchedProxyOverrideStore
        var cache: TTLCache<BatchedProxyOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedProxyOverrideStore, cache: TTLCache<BatchedProxyOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedProxyOverride? {
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

        func save(_ item: BatchedProxyOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedProxyOverride] {
            return inner.list()
        }
    }

    static func newCachedBatchedProxyOverrideStore(_ inner: MemoryBatchedProxyOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedProxyOverrideStore {
        return CachedBatchedProxyOverrideStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched proxy overrides. Empty fields match all.
    final class BatchedProxyOverrideQuery {
        var facility: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minMargin: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedProxyOverride) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedProxyOverride]) -> [BatchedProxyOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedProxyOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedProxyOverrides(_ store: any BatchedProxyOverrideStore, query: BatchedProxyOverrideQuery) -> [BatchedProxyOverride] {
        return query.apply(store.list())
    }
}
