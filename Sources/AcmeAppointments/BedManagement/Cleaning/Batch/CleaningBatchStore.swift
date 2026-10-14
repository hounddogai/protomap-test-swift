import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning batches by code.
    protocol CleaningBatchStore {
        func find(_ code: String) -> CleaningBatch?
        func save(_ item: CleaningBatch)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningBatchStore: CleaningBatchStore {
        var items: [String: CleaningBatch]
        var order: [String]

        init(items: [String: CleaningBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningBatch) {
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

        func list() -> [CleaningBatch] {
            var out: [CleaningBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningBatchStore() -> any CleaningBatchStore {
        return MemoryCleaningBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningBatchStore: CleaningBatchStore {
        var inner: MemoryCleaningBatchStore
        var cache: TTLCache<CleaningBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningBatchStore, cache: TTLCache<CleaningBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningBatch? {
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

        func save(_ item: CleaningBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningBatch] {
            return inner.list()
        }
    }

    static func newCachedCleaningBatchStore(_ inner: MemoryCleaningBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningBatchStore {
        return CachedCleaningBatchStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning batches. Empty fields match all.
    final class CleaningBatchQuery {
        var locale: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningBatch) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningBatch]) -> [CleaningBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningBatches(_ store: any CleaningBatchStore, query: CleaningBatchQuery) -> [CleaningBatch] {
        return query.apply(store.list())
    }
}
