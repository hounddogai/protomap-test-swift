import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps batched formulary bundles by code.
    protocol BatchedFormularyBundleStore {
        func find(_ code: String) -> BatchedFormularyBundle?
        func save(_ item: BatchedFormularyBundle)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedFormularyBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedFormularyBundleStore: BatchedFormularyBundleStore {
        var items: [String: BatchedFormularyBundle]
        var order: [String]

        init(items: [String: BatchedFormularyBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedFormularyBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedFormularyBundle) {
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

        func list() -> [BatchedFormularyBundle] {
            var out: [BatchedFormularyBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedFormularyBundleStore() -> any BatchedFormularyBundleStore {
        return MemoryBatchedFormularyBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedFormularyBundleStore: BatchedFormularyBundleStore {
        var inner: MemoryBatchedFormularyBundleStore
        var cache: TTLCache<BatchedFormularyBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedFormularyBundleStore, cache: TTLCache<BatchedFormularyBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedFormularyBundle? {
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

        func save(_ item: BatchedFormularyBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedFormularyBundle] {
            return inner.list()
        }
    }

    static func newCachedBatchedFormularyBundleStore(_ inner: MemoryBatchedFormularyBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedFormularyBundleStore {
        return CachedBatchedFormularyBundleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched formulary bundles. Empty fields match all.
    final class BatchedFormularyBundleQuery {
        var facility: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedFormularyBundle) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedFormularyBundle]) -> [BatchedFormularyBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedFormularyBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedFormularyBundles(_ store: any BatchedFormularyBundleStore, query: BatchedFormularyBundleQuery) -> [BatchedFormularyBundle] {
        return query.apply(store.list())
    }
}
