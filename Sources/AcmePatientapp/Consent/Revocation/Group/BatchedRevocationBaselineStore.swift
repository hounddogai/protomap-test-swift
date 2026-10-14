import AcmePlatform
import Foundation

extension Consent {
    /// Keeps batched revocation baselines by code.
    protocol BatchedRevocationBaselineStore {
        func find(_ code: String) -> BatchedRevocationBaseline?
        func save(_ item: BatchedRevocationBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedRevocationBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedRevocationBaselineStore: BatchedRevocationBaselineStore {
        var items: [String: BatchedRevocationBaseline]
        var order: [String]

        init(items: [String: BatchedRevocationBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedRevocationBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedRevocationBaseline) {
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

        func list() -> [BatchedRevocationBaseline] {
            var out: [BatchedRevocationBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedRevocationBaselineStore() -> any BatchedRevocationBaselineStore {
        return MemoryBatchedRevocationBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedRevocationBaselineStore: BatchedRevocationBaselineStore {
        var inner: MemoryBatchedRevocationBaselineStore
        var cache: TTLCache<BatchedRevocationBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedRevocationBaselineStore, cache: TTLCache<BatchedRevocationBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedRevocationBaseline? {
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

        func save(_ item: BatchedRevocationBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedRevocationBaseline] {
            return inner.list()
        }
    }

    static func newCachedBatchedRevocationBaselineStore(_ inner: MemoryBatchedRevocationBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedRevocationBaselineStore {
        return CachedBatchedRevocationBaselineStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched revocation baselines. Empty fields match all.
    final class BatchedRevocationBaselineQuery {
        var category: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minMargin: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedRevocationBaseline) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [BatchedRevocationBaseline]) -> [BatchedRevocationBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedRevocationBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedRevocationBaselines(_ store: any BatchedRevocationBaselineStore, query: BatchedRevocationBaselineQuery) -> [BatchedRevocationBaseline] {
        return query.apply(store.list())
    }
}
