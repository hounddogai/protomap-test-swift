import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps tiered interaction drafts by code.
    protocol TieredInteractionDraftStore {
        func find(_ code: String) -> TieredInteractionDraft?
        func save(_ item: TieredInteractionDraft)
        func remove(_ code: String) -> Bool
        func list() -> [TieredInteractionDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredInteractionDraftStore: TieredInteractionDraftStore {
        var items: [String: TieredInteractionDraft]
        var order: [String]

        init(items: [String: TieredInteractionDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredInteractionDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredInteractionDraft) {
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

        func list() -> [TieredInteractionDraft] {
            var out: [TieredInteractionDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredInteractionDraftStore() -> any TieredInteractionDraftStore {
        return MemoryTieredInteractionDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredInteractionDraftStore: TieredInteractionDraftStore {
        var inner: MemoryTieredInteractionDraftStore
        var cache: TTLCache<TieredInteractionDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredInteractionDraftStore, cache: TTLCache<TieredInteractionDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredInteractionDraft? {
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

        func save(_ item: TieredInteractionDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredInteractionDraft] {
            return inner.list()
        }
    }

    static func newCachedTieredInteractionDraftStore(_ inner: MemoryTieredInteractionDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredInteractionDraftStore {
        return CachedTieredInteractionDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered interaction drafts. Empty fields match all.
    final class TieredInteractionDraftQuery {
        var title: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRevision: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredInteractionDraft) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredInteractionDraft]) -> [TieredInteractionDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredInteractionDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredInteractionDrafts(_ store: any TieredInteractionDraftStore, query: TieredInteractionDraftQuery) -> [TieredInteractionDraft] {
        return query.apply(store.list())
    }
}
