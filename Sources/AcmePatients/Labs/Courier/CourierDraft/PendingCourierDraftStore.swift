import AcmePlatform
import Foundation

extension Labs {
    /// Keeps pending courier drafts by code.
    protocol PendingCourierDraftStore {
        func find(_ code: String) -> PendingCourierDraft?
        func save(_ item: PendingCourierDraft)
        func remove(_ code: String) -> Bool
        func list() -> [PendingCourierDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingCourierDraftStore: PendingCourierDraftStore {
        var items: [String: PendingCourierDraft]
        var order: [String]

        init(items: [String: PendingCourierDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingCourierDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingCourierDraft) {
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

        func list() -> [PendingCourierDraft] {
            var out: [PendingCourierDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingCourierDraftStore() -> any PendingCourierDraftStore {
        return MemoryPendingCourierDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingCourierDraftStore: PendingCourierDraftStore {
        var inner: MemoryPendingCourierDraftStore
        var cache: TTLCache<PendingCourierDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingCourierDraftStore, cache: TTLCache<PendingCourierDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingCourierDraft? {
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

        func save(_ item: PendingCourierDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingCourierDraft] {
            return inner.list()
        }
    }

    static func newCachedPendingCourierDraftStore(_ inner: MemoryPendingCourierDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingCourierDraftStore {
        return CachedPendingCourierDraftStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending courier drafts. Empty fields match all.
    final class PendingCourierDraftQuery {
        var title: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingCourierDraft) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingCourierDraft]) -> [PendingCourierDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingCourierDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingCourierDrafts(_ store: any PendingCourierDraftStore, query: PendingCourierDraftQuery) -> [PendingCourierDraft] {
        return query.apply(store.list())
    }
}
