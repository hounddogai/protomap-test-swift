import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall drafts by code.
    protocol RecallDraftStore {
        func find(_ code: String) -> RecallDraft?
        func save(_ item: RecallDraft)
        func remove(_ code: String) -> Bool
        func list() -> [RecallDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallDraftStore: RecallDraftStore {
        var items: [String: RecallDraft]
        var order: [String]

        init(items: [String: RecallDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallDraft) {
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

        func list() -> [RecallDraft] {
            var out: [RecallDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallDraftStore() -> any RecallDraftStore {
        return MemoryRecallDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallDraftStore: RecallDraftStore {
        var inner: MemoryRecallDraftStore
        var cache: TTLCache<RecallDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallDraftStore, cache: TTLCache<RecallDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallDraft? {
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

        func save(_ item: RecallDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallDraft] {
            return inner.list()
        }
    }

    static func newCachedRecallDraftStore(_ inner: MemoryRecallDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallDraftStore {
        return CachedRecallDraftStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall drafts. Empty fields match all.
    final class RecallDraftQuery {
        var unit: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallDraft) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RecallDraft]) -> [RecallDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallDrafts(_ store: any RecallDraftStore, query: RecallDraftQuery) -> [RecallDraft] {
        return query.apply(store.list())
    }
}
