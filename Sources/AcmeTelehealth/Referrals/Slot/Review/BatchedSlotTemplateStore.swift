import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps batched slot templates by code.
    protocol BatchedSlotTemplateStore {
        func find(_ code: String) -> BatchedSlotTemplate?
        func save(_ item: BatchedSlotTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedSlotTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedSlotTemplateStore: BatchedSlotTemplateStore {
        var items: [String: BatchedSlotTemplate]
        var order: [String]

        init(items: [String: BatchedSlotTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedSlotTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedSlotTemplate) {
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

        func list() -> [BatchedSlotTemplate] {
            var out: [BatchedSlotTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedSlotTemplateStore() -> any BatchedSlotTemplateStore {
        return MemoryBatchedSlotTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedSlotTemplateStore: BatchedSlotTemplateStore {
        var inner: MemoryBatchedSlotTemplateStore
        var cache: TTLCache<BatchedSlotTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedSlotTemplateStore, cache: TTLCache<BatchedSlotTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedSlotTemplate? {
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

        func save(_ item: BatchedSlotTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedSlotTemplate] {
            return inner.list()
        }
    }

    static func newCachedBatchedSlotTemplateStore(_ inner: MemoryBatchedSlotTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedSlotTemplateStore {
        return CachedBatchedSlotTemplateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched slot templates. Empty fields match all.
    final class BatchedSlotTemplateQuery {
        var source: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedSlotTemplate) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedSlotTemplate]) -> [BatchedSlotTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedSlotTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedSlotTemplates(_ store: any BatchedSlotTemplateStore, query: BatchedSlotTemplateQuery) -> [BatchedSlotTemplate] {
        return query.apply(store.list())
    }
}
