import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps scheduled follow up drafts by code.
    protocol ScheduledFollowUpDraftStore {
        func find(_ code: String) -> ScheduledFollowUpDraft?
        func save(_ item: ScheduledFollowUpDraft)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledFollowUpDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledFollowUpDraftStore: ScheduledFollowUpDraftStore {
        var items: [String: ScheduledFollowUpDraft]
        var order: [String]

        init(items: [String: ScheduledFollowUpDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledFollowUpDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledFollowUpDraft) {
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

        func list() -> [ScheduledFollowUpDraft] {
            var out: [ScheduledFollowUpDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledFollowUpDraftStore() -> any ScheduledFollowUpDraftStore {
        return MemoryScheduledFollowUpDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledFollowUpDraftStore: ScheduledFollowUpDraftStore {
        var inner: MemoryScheduledFollowUpDraftStore
        var cache: TTLCache<ScheduledFollowUpDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledFollowUpDraftStore, cache: TTLCache<ScheduledFollowUpDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledFollowUpDraft? {
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

        func save(_ item: ScheduledFollowUpDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledFollowUpDraft] {
            return inner.list()
        }
    }

    static func newCachedScheduledFollowUpDraftStore(_ inner: MemoryScheduledFollowUpDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledFollowUpDraftStore {
        return CachedScheduledFollowUpDraftStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled follow up drafts. Empty fields match all.
    final class ScheduledFollowUpDraftQuery {
        var label: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minLimit: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledFollowUpDraft) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ScheduledFollowUpDraft]) -> [ScheduledFollowUpDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledFollowUpDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledFollowUpDrafts(_ store: any ScheduledFollowUpDraftStore, query: ScheduledFollowUpDraftQuery) -> [ScheduledFollowUpDraft] {
        return query.apply(store.list())
    }
}
