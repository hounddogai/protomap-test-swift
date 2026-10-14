import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps regional study batches by code.
    protocol RegionalStudyBatchStore {
        func find(_ code: String) -> RegionalStudyBatch?
        func save(_ item: RegionalStudyBatch)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalStudyBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalStudyBatchStore: RegionalStudyBatchStore {
        var items: [String: RegionalStudyBatch]
        var order: [String]

        init(items: [String: RegionalStudyBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalStudyBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalStudyBatch) {
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

        func list() -> [RegionalStudyBatch] {
            var out: [RegionalStudyBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalStudyBatchStore() -> any RegionalStudyBatchStore {
        return MemoryRegionalStudyBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalStudyBatchStore: RegionalStudyBatchStore {
        var inner: MemoryRegionalStudyBatchStore
        var cache: TTLCache<RegionalStudyBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalStudyBatchStore, cache: TTLCache<RegionalStudyBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalStudyBatch? {
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

        func save(_ item: RegionalStudyBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalStudyBatch] {
            return inner.list()
        }
    }

    static func newCachedRegionalStudyBatchStore(_ inner: MemoryRegionalStudyBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalStudyBatchStore {
        return CachedRegionalStudyBatchStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional study batches. Empty fields match all.
    final class RegionalStudyBatchQuery {
        var label: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRevision: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalStudyBatch) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalStudyBatch]) -> [RegionalStudyBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalStudyBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalStudyBatches(_ store: any RegionalStudyBatchStore, query: RegionalStudyBatchQuery) -> [RegionalStudyBatch] {
        return query.apply(store.list())
    }
}
