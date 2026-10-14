import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps batched discharge plan drafts by code.
    protocol BatchedDischargePlanDraftStore {
        func find(_ code: String) -> BatchedDischargePlanDraft?
        func save(_ item: BatchedDischargePlanDraft)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedDischargePlanDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedDischargePlanDraftStore: BatchedDischargePlanDraftStore {
        var items: [String: BatchedDischargePlanDraft]
        var order: [String]

        init(items: [String: BatchedDischargePlanDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedDischargePlanDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedDischargePlanDraft) {
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

        func list() -> [BatchedDischargePlanDraft] {
            var out: [BatchedDischargePlanDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedDischargePlanDraftStore() -> any BatchedDischargePlanDraftStore {
        return MemoryBatchedDischargePlanDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedDischargePlanDraftStore: BatchedDischargePlanDraftStore {
        var inner: MemoryBatchedDischargePlanDraftStore
        var cache: TTLCache<BatchedDischargePlanDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedDischargePlanDraftStore, cache: TTLCache<BatchedDischargePlanDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedDischargePlanDraft? {
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

        func save(_ item: BatchedDischargePlanDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedDischargePlanDraft] {
            return inner.list()
        }
    }

    static func newCachedBatchedDischargePlanDraftStore(_ inner: MemoryBatchedDischargePlanDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedDischargePlanDraftStore {
        return CachedBatchedDischargePlanDraftStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched discharge plan drafts. Empty fields match all.
    final class BatchedDischargePlanDraftQuery {
        var name: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRate: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedDischargePlanDraft) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedDischargePlanDraft]) -> [BatchedDischargePlanDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedDischargePlanDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedDischargePlanDrafts(_ store: any BatchedDischargePlanDraftStore, query: BatchedDischargePlanDraftQuery) -> [BatchedDischargePlanDraft] {
        return query.apply(store.list())
    }
}
