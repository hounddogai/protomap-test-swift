import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps batched program drafts by code.
    protocol BatchedProgramDraftStore {
        func find(_ code: String) -> BatchedProgramDraft?
        func save(_ item: BatchedProgramDraft)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedProgramDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedProgramDraftStore: BatchedProgramDraftStore {
        var items: [String: BatchedProgramDraft]
        var order: [String]

        init(items: [String: BatchedProgramDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedProgramDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedProgramDraft) {
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

        func list() -> [BatchedProgramDraft] {
            var out: [BatchedProgramDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedProgramDraftStore() -> any BatchedProgramDraftStore {
        return MemoryBatchedProgramDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedProgramDraftStore: BatchedProgramDraftStore {
        var inner: MemoryBatchedProgramDraftStore
        var cache: TTLCache<BatchedProgramDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedProgramDraftStore, cache: TTLCache<BatchedProgramDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedProgramDraft? {
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

        func save(_ item: BatchedProgramDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedProgramDraft] {
            return inner.list()
        }
    }

    static func newCachedBatchedProgramDraftStore(_ inner: MemoryBatchedProgramDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedProgramDraftStore {
        return CachedBatchedProgramDraftStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched program drafts. Empty fields match all.
    final class BatchedProgramDraftQuery {
        var title: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minLimit: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedProgramDraft) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedProgramDraft]) -> [BatchedProgramDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedProgramDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedProgramDrafts(_ store: any BatchedProgramDraftStore, query: BatchedProgramDraftQuery) -> [BatchedProgramDraft] {
        return query.apply(store.list())
    }
}
