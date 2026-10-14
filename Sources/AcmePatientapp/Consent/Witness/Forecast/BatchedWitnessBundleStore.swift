import AcmePlatform
import Foundation

extension Consent {
    /// Keeps batched witness bundles by code.
    protocol BatchedWitnessBundleStore {
        func find(_ code: String) -> BatchedWitnessBundle?
        func save(_ item: BatchedWitnessBundle)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedWitnessBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedWitnessBundleStore: BatchedWitnessBundleStore {
        var items: [String: BatchedWitnessBundle]
        var order: [String]

        init(items: [String: BatchedWitnessBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedWitnessBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedWitnessBundle) {
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

        func list() -> [BatchedWitnessBundle] {
            var out: [BatchedWitnessBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedWitnessBundleStore() -> any BatchedWitnessBundleStore {
        return MemoryBatchedWitnessBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedWitnessBundleStore: BatchedWitnessBundleStore {
        var inner: MemoryBatchedWitnessBundleStore
        var cache: TTLCache<BatchedWitnessBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedWitnessBundleStore, cache: TTLCache<BatchedWitnessBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedWitnessBundle? {
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

        func save(_ item: BatchedWitnessBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedWitnessBundle] {
            return inner.list()
        }
    }

    static func newCachedBatchedWitnessBundleStore(_ inner: MemoryBatchedWitnessBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedWitnessBundleStore {
        return CachedBatchedWitnessBundleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched witness bundles. Empty fields match all.
    final class BatchedWitnessBundleQuery {
        var name: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedWitnessBundle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedWitnessBundle]) -> [BatchedWitnessBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedWitnessBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedWitnessBundles(_ store: any BatchedWitnessBundleStore, query: BatchedWitnessBundleQuery) -> [BatchedWitnessBundle] {
        return query.apply(store.list())
    }
}
