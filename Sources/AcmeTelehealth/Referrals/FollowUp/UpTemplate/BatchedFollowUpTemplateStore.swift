import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps batched follow up templates by code.
    protocol BatchedFollowUpTemplateStore {
        func find(_ code: String) -> BatchedFollowUpTemplate?
        func save(_ item: BatchedFollowUpTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedFollowUpTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedFollowUpTemplateStore: BatchedFollowUpTemplateStore {
        var items: [String: BatchedFollowUpTemplate]
        var order: [String]

        init(items: [String: BatchedFollowUpTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedFollowUpTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedFollowUpTemplate) {
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

        func list() -> [BatchedFollowUpTemplate] {
            var out: [BatchedFollowUpTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedFollowUpTemplateStore() -> any BatchedFollowUpTemplateStore {
        return MemoryBatchedFollowUpTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedFollowUpTemplateStore: BatchedFollowUpTemplateStore {
        var inner: MemoryBatchedFollowUpTemplateStore
        var cache: TTLCache<BatchedFollowUpTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedFollowUpTemplateStore, cache: TTLCache<BatchedFollowUpTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedFollowUpTemplate? {
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

        func save(_ item: BatchedFollowUpTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedFollowUpTemplate] {
            return inner.list()
        }
    }

    static func newCachedBatchedFollowUpTemplateStore(_ inner: MemoryBatchedFollowUpTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedFollowUpTemplateStore {
        return CachedBatchedFollowUpTemplateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched follow up templates. Empty fields match all.
    final class BatchedFollowUpTemplateQuery {
        var source: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedFollowUpTemplate) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedFollowUpTemplate]) -> [BatchedFollowUpTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedFollowUpTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedFollowUpTemplates(_ store: any BatchedFollowUpTemplateStore, query: BatchedFollowUpTemplateQuery) -> [BatchedFollowUpTemplate] {
        return query.apply(store.list())
    }
}
