import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps regional modality batches by code.
    protocol RegionalModalityBatchStore {
        func find(_ code: String) -> RegionalModalityBatch?
        func save(_ item: RegionalModalityBatch)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalModalityBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalModalityBatchStore: RegionalModalityBatchStore {
        var items: [String: RegionalModalityBatch]
        var order: [String]

        init(items: [String: RegionalModalityBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalModalityBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalModalityBatch) {
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

        func list() -> [RegionalModalityBatch] {
            var out: [RegionalModalityBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalModalityBatchStore() -> any RegionalModalityBatchStore {
        return MemoryRegionalModalityBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalModalityBatchStore: RegionalModalityBatchStore {
        var inner: MemoryRegionalModalityBatchStore
        var cache: TTLCache<RegionalModalityBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalModalityBatchStore, cache: TTLCache<RegionalModalityBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalModalityBatch? {
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

        func save(_ item: RegionalModalityBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalModalityBatch] {
            return inner.list()
        }
    }

    static func newCachedRegionalModalityBatchStore(_ inner: MemoryRegionalModalityBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalModalityBatchStore {
        return CachedRegionalModalityBatchStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional modality batches. Empty fields match all.
    final class RegionalModalityBatchQuery {
        var label: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minPriority: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalModalityBatch) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalModalityBatch]) -> [RegionalModalityBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalModalityBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalModalityBatches(_ store: any RegionalModalityBatchStore, query: RegionalModalityBatchQuery) -> [RegionalModalityBatch] {
        return query.apply(store.list())
    }
}
