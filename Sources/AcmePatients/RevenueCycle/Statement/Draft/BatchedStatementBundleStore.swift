import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps batched statement bundles by code.
    protocol BatchedStatementBundleStore {
        func find(_ code: String) -> BatchedStatementBundle?
        func save(_ item: BatchedStatementBundle)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedStatementBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedStatementBundleStore: BatchedStatementBundleStore {
        var items: [String: BatchedStatementBundle]
        var order: [String]

        init(items: [String: BatchedStatementBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedStatementBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedStatementBundle) {
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

        func list() -> [BatchedStatementBundle] {
            var out: [BatchedStatementBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedStatementBundleStore() -> any BatchedStatementBundleStore {
        return MemoryBatchedStatementBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedStatementBundleStore: BatchedStatementBundleStore {
        var inner: MemoryBatchedStatementBundleStore
        var cache: TTLCache<BatchedStatementBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedStatementBundleStore, cache: TTLCache<BatchedStatementBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedStatementBundle? {
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

        func save(_ item: BatchedStatementBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedStatementBundle] {
            return inner.list()
        }
    }

    static func newCachedBatchedStatementBundleStore(_ inner: MemoryBatchedStatementBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedStatementBundleStore {
        return CachedBatchedStatementBundleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched statement bundles. Empty fields match all.
    final class BatchedStatementBundleQuery {
        var country: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedStatementBundle) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedStatementBundle]) -> [BatchedStatementBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedStatementBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedStatementBundles(_ store: any BatchedStatementBundleStore, query: BatchedStatementBundleQuery) -> [BatchedStatementBundle] {
        return query.apply(store.list())
    }
}
