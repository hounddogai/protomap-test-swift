import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps batched care gap bundles by code.
    protocol BatchedCareGapBundleStore {
        func find(_ code: String) -> BatchedCareGapBundle?
        func save(_ item: BatchedCareGapBundle)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedCareGapBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedCareGapBundleStore: BatchedCareGapBundleStore {
        var items: [String: BatchedCareGapBundle]
        var order: [String]

        init(items: [String: BatchedCareGapBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedCareGapBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedCareGapBundle) {
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

        func list() -> [BatchedCareGapBundle] {
            var out: [BatchedCareGapBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedCareGapBundleStore() -> any BatchedCareGapBundleStore {
        return MemoryBatchedCareGapBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedCareGapBundleStore: BatchedCareGapBundleStore {
        var inner: MemoryBatchedCareGapBundleStore
        var cache: TTLCache<BatchedCareGapBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedCareGapBundleStore, cache: TTLCache<BatchedCareGapBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedCareGapBundle? {
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

        func save(_ item: BatchedCareGapBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedCareGapBundle] {
            return inner.list()
        }
    }

    static func newCachedBatchedCareGapBundleStore(_ inner: MemoryBatchedCareGapBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedCareGapBundleStore {
        return CachedBatchedCareGapBundleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched care gap bundles. Empty fields match all.
    final class BatchedCareGapBundleQuery {
        var country: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minWeight: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedCareGapBundle) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedCareGapBundle]) -> [BatchedCareGapBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedCareGapBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedCareGapBundles(_ store: any BatchedCareGapBundleStore, query: BatchedCareGapBundleQuery) -> [BatchedCareGapBundle] {
        return query.apply(store.list())
    }
}
