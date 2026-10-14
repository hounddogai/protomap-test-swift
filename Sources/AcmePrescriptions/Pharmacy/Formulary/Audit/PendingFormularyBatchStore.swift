import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps pending formulary batches by code.
    protocol PendingFormularyBatchStore {
        func find(_ code: String) -> PendingFormularyBatch?
        func save(_ item: PendingFormularyBatch)
        func remove(_ code: String) -> Bool
        func list() -> [PendingFormularyBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingFormularyBatchStore: PendingFormularyBatchStore {
        var items: [String: PendingFormularyBatch]
        var order: [String]

        init(items: [String: PendingFormularyBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingFormularyBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingFormularyBatch) {
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

        func list() -> [PendingFormularyBatch] {
            var out: [PendingFormularyBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingFormularyBatchStore() -> any PendingFormularyBatchStore {
        return MemoryPendingFormularyBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingFormularyBatchStore: PendingFormularyBatchStore {
        var inner: MemoryPendingFormularyBatchStore
        var cache: TTLCache<PendingFormularyBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingFormularyBatchStore, cache: TTLCache<PendingFormularyBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingFormularyBatch? {
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

        func save(_ item: PendingFormularyBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingFormularyBatch] {
            return inner.list()
        }
    }

    static func newCachedPendingFormularyBatchStore(_ inner: MemoryPendingFormularyBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingFormularyBatchStore {
        return CachedPendingFormularyBatchStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending formulary batches. Empty fields match all.
    final class PendingFormularyBatchQuery {
        var label: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingFormularyBatch) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingFormularyBatch]) -> [PendingFormularyBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingFormularyBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingFormularyBatches(_ store: any PendingFormularyBatchStore, query: PendingFormularyBatchQuery) -> [PendingFormularyBatch] {
        return query.apply(store.list())
    }
}
