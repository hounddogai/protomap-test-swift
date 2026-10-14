import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps fallback program batches by code.
    protocol FallbackProgramBatchStore {
        func find(_ code: String) -> FallbackProgramBatch?
        func save(_ item: FallbackProgramBatch)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackProgramBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackProgramBatchStore: FallbackProgramBatchStore {
        var items: [String: FallbackProgramBatch]
        var order: [String]

        init(items: [String: FallbackProgramBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackProgramBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackProgramBatch) {
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

        func list() -> [FallbackProgramBatch] {
            var out: [FallbackProgramBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackProgramBatchStore() -> any FallbackProgramBatchStore {
        return MemoryFallbackProgramBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackProgramBatchStore: FallbackProgramBatchStore {
        var inner: MemoryFallbackProgramBatchStore
        var cache: TTLCache<FallbackProgramBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackProgramBatchStore, cache: TTLCache<FallbackProgramBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackProgramBatch? {
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

        func save(_ item: FallbackProgramBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackProgramBatch] {
            return inner.list()
        }
    }

    static func newCachedFallbackProgramBatchStore(_ inner: MemoryFallbackProgramBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackProgramBatchStore {
        return CachedFallbackProgramBatchStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback program batches. Empty fields match all.
    final class FallbackProgramBatchQuery {
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

        func matches(_ item: FallbackProgramBatch) -> Bool {
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

        func apply(_ items: [FallbackProgramBatch]) -> [FallbackProgramBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackProgramBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackProgramBatches(_ store: any FallbackProgramBatchStore, query: FallbackProgramBatchQuery) -> [FallbackProgramBatch] {
        return query.apply(store.list())
    }
}
