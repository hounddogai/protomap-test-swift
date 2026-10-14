import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel drafts by code.
    protocol PanelDraftStore {
        func find(_ code: String) -> PanelDraft?
        func save(_ item: PanelDraft)
        func remove(_ code: String) -> Bool
        func list() -> [PanelDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelDraftStore: PanelDraftStore {
        var items: [String: PanelDraft]
        var order: [String]

        init(items: [String: PanelDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelDraft) {
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

        func list() -> [PanelDraft] {
            var out: [PanelDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelDraftStore() -> any PanelDraftStore {
        return MemoryPanelDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelDraftStore: PanelDraftStore {
        var inner: MemoryPanelDraftStore
        var cache: TTLCache<PanelDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelDraftStore, cache: TTLCache<PanelDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelDraft? {
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

        func save(_ item: PanelDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelDraft] {
            return inner.list()
        }
    }

    static func newCachedPanelDraftStore(_ inner: MemoryPanelDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelDraftStore {
        return CachedPanelDraftStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel drafts. Empty fields match all.
    final class PanelDraftQuery {
        var title: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelDraft) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PanelDraft]) -> [PanelDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelDrafts(_ store: any PanelDraftStore, query: PanelDraftQuery) -> [PanelDraft] {
        return query.apply(store.list())
    }
}
