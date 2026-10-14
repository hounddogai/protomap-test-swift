import AcmePlatform
import Foundation

extension Labs {
    /// Keeps global reference range batches by code.
    protocol GlobalReferenceRangeBatchStore {
        func find(_ code: String) -> GlobalReferenceRangeBatch?
        func save(_ item: GlobalReferenceRangeBatch)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalReferenceRangeBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalReferenceRangeBatchStore: GlobalReferenceRangeBatchStore {
        var items: [String: GlobalReferenceRangeBatch]
        var order: [String]

        init(items: [String: GlobalReferenceRangeBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalReferenceRangeBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalReferenceRangeBatch) {
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

        func list() -> [GlobalReferenceRangeBatch] {
            var out: [GlobalReferenceRangeBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalReferenceRangeBatchStore() -> any GlobalReferenceRangeBatchStore {
        return MemoryGlobalReferenceRangeBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalReferenceRangeBatchStore: GlobalReferenceRangeBatchStore {
        var inner: MemoryGlobalReferenceRangeBatchStore
        var cache: TTLCache<GlobalReferenceRangeBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalReferenceRangeBatchStore, cache: TTLCache<GlobalReferenceRangeBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalReferenceRangeBatch? {
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

        func save(_ item: GlobalReferenceRangeBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalReferenceRangeBatch] {
            return inner.list()
        }
    }

    static func newCachedGlobalReferenceRangeBatchStore(_ inner: MemoryGlobalReferenceRangeBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalReferenceRangeBatchStore {
        return CachedGlobalReferenceRangeBatchStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global reference range batches. Empty fields match all.
    final class GlobalReferenceRangeBatchQuery {
        var title: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalReferenceRangeBatch) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalReferenceRangeBatch]) -> [GlobalReferenceRangeBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalReferenceRangeBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalReferenceRangeBatches(_ store: any GlobalReferenceRangeBatchStore, query: GlobalReferenceRangeBatchQuery) -> [GlobalReferenceRangeBatch] {
        return query.apply(store.list())
    }
}
