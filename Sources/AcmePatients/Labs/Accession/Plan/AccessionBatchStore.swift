import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession batches by code.
    protocol AccessionBatchStore {
        func find(_ code: String) -> AccessionBatch?
        func save(_ item: AccessionBatch)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionBatchStore: AccessionBatchStore {
        var items: [String: AccessionBatch]
        var order: [String]

        init(items: [String: AccessionBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionBatch) {
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

        func list() -> [AccessionBatch] {
            var out: [AccessionBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionBatchStore() -> any AccessionBatchStore {
        return MemoryAccessionBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionBatchStore: AccessionBatchStore {
        var inner: MemoryAccessionBatchStore
        var cache: TTLCache<AccessionBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionBatchStore, cache: TTLCache<AccessionBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionBatch? {
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

        func save(_ item: AccessionBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionBatch] {
            return inner.list()
        }
    }

    static func newCachedAccessionBatchStore(_ inner: MemoryAccessionBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionBatchStore {
        return CachedAccessionBatchStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession batches. Empty fields match all.
    final class AccessionBatchQuery {
        var title: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionBatch) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AccessionBatch]) -> [AccessionBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionBatches(_ store: any AccessionBatchStore, query: AccessionBatchQuery) -> [AccessionBatch] {
        return query.apply(store.list())
    }
}
