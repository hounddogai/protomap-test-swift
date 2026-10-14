import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps batched eligibility drafts by code.
    protocol BatchedEligibilityDraftStore {
        func find(_ code: String) -> BatchedEligibilityDraft?
        func save(_ item: BatchedEligibilityDraft)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedEligibilityDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedEligibilityDraftStore: BatchedEligibilityDraftStore {
        var items: [String: BatchedEligibilityDraft]
        var order: [String]

        init(items: [String: BatchedEligibilityDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedEligibilityDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedEligibilityDraft) {
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

        func list() -> [BatchedEligibilityDraft] {
            var out: [BatchedEligibilityDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedEligibilityDraftStore() -> any BatchedEligibilityDraftStore {
        return MemoryBatchedEligibilityDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedEligibilityDraftStore: BatchedEligibilityDraftStore {
        var inner: MemoryBatchedEligibilityDraftStore
        var cache: TTLCache<BatchedEligibilityDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedEligibilityDraftStore, cache: TTLCache<BatchedEligibilityDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedEligibilityDraft? {
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

        func save(_ item: BatchedEligibilityDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedEligibilityDraft] {
            return inner.list()
        }
    }

    static func newCachedBatchedEligibilityDraftStore(_ inner: MemoryBatchedEligibilityDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedEligibilityDraftStore {
        return CachedBatchedEligibilityDraftStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched eligibility drafts. Empty fields match all.
    final class BatchedEligibilityDraftQuery {
        var title: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedEligibilityDraft) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [BatchedEligibilityDraft]) -> [BatchedEligibilityDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedEligibilityDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedEligibilityDrafts(_ store: any BatchedEligibilityDraftStore, query: BatchedEligibilityDraftQuery) -> [BatchedEligibilityDraft] {
        return query.apply(store.list())
    }
}
