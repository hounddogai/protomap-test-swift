import AcmePlatform
import Foundation

extension Labs {
    /// Keeps fallback reference range batches by code.
    protocol FallbackReferenceRangeBatchStore {
        func find(_ code: String) -> FallbackReferenceRangeBatch?
        func save(_ item: FallbackReferenceRangeBatch)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackReferenceRangeBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackReferenceRangeBatchStore: FallbackReferenceRangeBatchStore {
        var items: [String: FallbackReferenceRangeBatch]
        var order: [String]

        init(items: [String: FallbackReferenceRangeBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackReferenceRangeBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackReferenceRangeBatch) {
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

        func list() -> [FallbackReferenceRangeBatch] {
            var out: [FallbackReferenceRangeBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackReferenceRangeBatchStore() -> any FallbackReferenceRangeBatchStore {
        return MemoryFallbackReferenceRangeBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackReferenceRangeBatchStore: FallbackReferenceRangeBatchStore {
        var inner: MemoryFallbackReferenceRangeBatchStore
        var cache: TTLCache<FallbackReferenceRangeBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackReferenceRangeBatchStore, cache: TTLCache<FallbackReferenceRangeBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackReferenceRangeBatch? {
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

        func save(_ item: FallbackReferenceRangeBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackReferenceRangeBatch] {
            return inner.list()
        }
    }

    static func newCachedFallbackReferenceRangeBatchStore(_ inner: MemoryFallbackReferenceRangeBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackReferenceRangeBatchStore {
        return CachedFallbackReferenceRangeBatchStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback reference range batches. Empty fields match all.
    final class FallbackReferenceRangeBatchQuery {
        var title: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRefills: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackReferenceRangeBatch) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackReferenceRangeBatch]) -> [FallbackReferenceRangeBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackReferenceRangeBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackReferenceRangeBatches(_ store: any FallbackReferenceRangeBatchStore, query: FallbackReferenceRangeBatchQuery) -> [FallbackReferenceRangeBatch] {
        return query.apply(store.list())
    }
}
