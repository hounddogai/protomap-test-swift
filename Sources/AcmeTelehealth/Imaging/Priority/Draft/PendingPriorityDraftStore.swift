import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps pending priority drafts by code.
    protocol PendingPriorityDraftStore {
        func find(_ code: String) -> PendingPriorityDraft?
        func save(_ item: PendingPriorityDraft)
        func remove(_ code: String) -> Bool
        func list() -> [PendingPriorityDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingPriorityDraftStore: PendingPriorityDraftStore {
        var items: [String: PendingPriorityDraft]
        var order: [String]

        init(items: [String: PendingPriorityDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingPriorityDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingPriorityDraft) {
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

        func list() -> [PendingPriorityDraft] {
            var out: [PendingPriorityDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingPriorityDraftStore() -> any PendingPriorityDraftStore {
        return MemoryPendingPriorityDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingPriorityDraftStore: PendingPriorityDraftStore {
        var inner: MemoryPendingPriorityDraftStore
        var cache: TTLCache<PendingPriorityDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingPriorityDraftStore, cache: TTLCache<PendingPriorityDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingPriorityDraft? {
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

        func save(_ item: PendingPriorityDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingPriorityDraft] {
            return inner.list()
        }
    }

    static func newCachedPendingPriorityDraftStore(_ inner: MemoryPendingPriorityDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingPriorityDraftStore {
        return CachedPendingPriorityDraftStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending priority drafts. Empty fields match all.
    final class PendingPriorityDraftQuery {
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

        func matches(_ item: PendingPriorityDraft) -> Bool {
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

        func apply(_ items: [PendingPriorityDraft]) -> [PendingPriorityDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingPriorityDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingPriorityDrafts(_ store: any PendingPriorityDraftStore, query: PendingPriorityDraftQuery) -> [PendingPriorityDraft] {
        return query.apply(store.list())
    }
}
