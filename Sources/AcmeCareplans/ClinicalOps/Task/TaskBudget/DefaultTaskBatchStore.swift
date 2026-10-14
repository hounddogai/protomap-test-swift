import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps default task batches by code.
    protocol DefaultTaskBatchStore {
        func find(_ code: String) -> DefaultTaskBatch?
        func save(_ item: DefaultTaskBatch)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultTaskBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultTaskBatchStore: DefaultTaskBatchStore {
        var items: [String: DefaultTaskBatch]
        var order: [String]

        init(items: [String: DefaultTaskBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultTaskBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultTaskBatch) {
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

        func list() -> [DefaultTaskBatch] {
            var out: [DefaultTaskBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultTaskBatchStore() -> any DefaultTaskBatchStore {
        return MemoryDefaultTaskBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultTaskBatchStore: DefaultTaskBatchStore {
        var inner: MemoryDefaultTaskBatchStore
        var cache: TTLCache<DefaultTaskBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultTaskBatchStore, cache: TTLCache<DefaultTaskBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultTaskBatch? {
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

        func save(_ item: DefaultTaskBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultTaskBatch] {
            return inner.list()
        }
    }

    static func newCachedDefaultTaskBatchStore(_ inner: MemoryDefaultTaskBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultTaskBatchStore {
        return CachedDefaultTaskBatchStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default task batches. Empty fields match all.
    final class DefaultTaskBatchQuery {
        var facility: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultTaskBatch) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultTaskBatch]) -> [DefaultTaskBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultTaskBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultTaskBatches(_ store: any DefaultTaskBatchStore, query: DefaultTaskBatchQuery) -> [DefaultTaskBatch] {
        return query.apply(store.list())
    }
}
