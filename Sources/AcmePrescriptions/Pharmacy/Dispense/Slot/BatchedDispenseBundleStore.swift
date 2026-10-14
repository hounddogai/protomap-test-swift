import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps batched dispense bundles by code.
    protocol BatchedDispenseBundleStore {
        func find(_ code: String) -> BatchedDispenseBundle?
        func save(_ item: BatchedDispenseBundle)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedDispenseBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedDispenseBundleStore: BatchedDispenseBundleStore {
        var items: [String: BatchedDispenseBundle]
        var order: [String]

        init(items: [String: BatchedDispenseBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedDispenseBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedDispenseBundle) {
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

        func list() -> [BatchedDispenseBundle] {
            var out: [BatchedDispenseBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedDispenseBundleStore() -> any BatchedDispenseBundleStore {
        return MemoryBatchedDispenseBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedDispenseBundleStore: BatchedDispenseBundleStore {
        var inner: MemoryBatchedDispenseBundleStore
        var cache: TTLCache<BatchedDispenseBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedDispenseBundleStore, cache: TTLCache<BatchedDispenseBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedDispenseBundle? {
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

        func save(_ item: BatchedDispenseBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedDispenseBundle] {
            return inner.list()
        }
    }

    static func newCachedBatchedDispenseBundleStore(_ inner: MemoryBatchedDispenseBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedDispenseBundleStore {
        return CachedBatchedDispenseBundleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched dispense bundles. Empty fields match all.
    final class BatchedDispenseBundleQuery {
        var facility: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minRetries: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedDispenseBundle) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedDispenseBundle]) -> [BatchedDispenseBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedDispenseBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedDispenseBundles(_ store: any BatchedDispenseBundleStore, query: BatchedDispenseBundleQuery) -> [BatchedDispenseBundle] {
        return query.apply(store.list())
    }
}
