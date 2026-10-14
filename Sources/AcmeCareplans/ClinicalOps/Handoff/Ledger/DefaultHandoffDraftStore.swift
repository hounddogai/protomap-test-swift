import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps default handoff drafts by code.
    protocol DefaultHandoffDraftStore {
        func find(_ code: String) -> DefaultHandoffDraft?
        func save(_ item: DefaultHandoffDraft)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultHandoffDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultHandoffDraftStore: DefaultHandoffDraftStore {
        var items: [String: DefaultHandoffDraft]
        var order: [String]

        init(items: [String: DefaultHandoffDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultHandoffDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultHandoffDraft) {
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

        func list() -> [DefaultHandoffDraft] {
            var out: [DefaultHandoffDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultHandoffDraftStore() -> any DefaultHandoffDraftStore {
        return MemoryDefaultHandoffDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultHandoffDraftStore: DefaultHandoffDraftStore {
        var inner: MemoryDefaultHandoffDraftStore
        var cache: TTLCache<DefaultHandoffDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultHandoffDraftStore, cache: TTLCache<DefaultHandoffDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultHandoffDraft? {
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

        func save(_ item: DefaultHandoffDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultHandoffDraft] {
            return inner.list()
        }
    }

    static func newCachedDefaultHandoffDraftStore(_ inner: MemoryDefaultHandoffDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultHandoffDraftStore {
        return CachedDefaultHandoffDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default handoff drafts. Empty fields match all.
    final class DefaultHandoffDraftQuery {
        var segment: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultHandoffDraft) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultHandoffDraft]) -> [DefaultHandoffDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultHandoffDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultHandoffDrafts(_ store: any DefaultHandoffDraftStore, query: DefaultHandoffDraftQuery) -> [DefaultHandoffDraft] {
        return query.apply(store.list())
    }
}
