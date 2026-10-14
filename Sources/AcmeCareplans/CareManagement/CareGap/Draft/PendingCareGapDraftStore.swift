import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps pending care gap drafts by code.
    protocol PendingCareGapDraftStore {
        func find(_ code: String) -> PendingCareGapDraft?
        func save(_ item: PendingCareGapDraft)
        func remove(_ code: String) -> Bool
        func list() -> [PendingCareGapDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingCareGapDraftStore: PendingCareGapDraftStore {
        var items: [String: PendingCareGapDraft]
        var order: [String]

        init(items: [String: PendingCareGapDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingCareGapDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingCareGapDraft) {
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

        func list() -> [PendingCareGapDraft] {
            var out: [PendingCareGapDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingCareGapDraftStore() -> any PendingCareGapDraftStore {
        return MemoryPendingCareGapDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingCareGapDraftStore: PendingCareGapDraftStore {
        var inner: MemoryPendingCareGapDraftStore
        var cache: TTLCache<PendingCareGapDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingCareGapDraftStore, cache: TTLCache<PendingCareGapDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingCareGapDraft? {
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

        func save(_ item: PendingCareGapDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingCareGapDraft] {
            return inner.list()
        }
    }

    static func newCachedPendingCareGapDraftStore(_ inner: MemoryPendingCareGapDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingCareGapDraftStore {
        return CachedPendingCareGapDraftStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending care gap drafts. Empty fields match all.
    final class PendingCareGapDraftQuery {
        var name: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingCareGapDraft) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [PendingCareGapDraft]) -> [PendingCareGapDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingCareGapDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingCareGapDrafts(_ store: any PendingCareGapDraftStore, query: PendingCareGapDraftQuery) -> [PendingCareGapDraft] {
        return query.apply(store.list())
    }
}
