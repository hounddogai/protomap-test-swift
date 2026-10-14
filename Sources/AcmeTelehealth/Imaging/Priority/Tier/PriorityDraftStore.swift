import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority drafts by code.
    protocol PriorityDraftStore {
        func find(_ code: String) -> PriorityDraft?
        func save(_ item: PriorityDraft)
        func remove(_ code: String) -> Bool
        func list() -> [PriorityDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPriorityDraftStore: PriorityDraftStore {
        var items: [String: PriorityDraft]
        var order: [String]

        init(items: [String: PriorityDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PriorityDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PriorityDraft) {
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

        func list() -> [PriorityDraft] {
            var out: [PriorityDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPriorityDraftStore() -> any PriorityDraftStore {
        return MemoryPriorityDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPriorityDraftStore: PriorityDraftStore {
        var inner: MemoryPriorityDraftStore
        var cache: TTLCache<PriorityDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryPriorityDraftStore, cache: TTLCache<PriorityDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PriorityDraft? {
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

        func save(_ item: PriorityDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PriorityDraft] {
            return inner.list()
        }
    }

    static func newCachedPriorityDraftStore(_ inner: MemoryPriorityDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PriorityDraftStore {
        return CachedPriorityDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority drafts. Empty fields match all.
    final class PriorityDraftQuery {
        var title: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PriorityDraft) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PriorityDraft]) -> [PriorityDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PriorityDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPriorityDrafts(_ store: any PriorityDraftStore, query: PriorityDraftQuery) -> [PriorityDraft] {
        return query.apply(store.list())
    }
}
