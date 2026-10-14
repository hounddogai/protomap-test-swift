import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps slot drafts by code.
    protocol SlotDraftStore {
        func find(_ code: String) -> SlotDraft?
        func save(_ item: SlotDraft)
        func remove(_ code: String) -> Bool
        func list() -> [SlotDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySlotDraftStore: SlotDraftStore {
        var items: [String: SlotDraft]
        var order: [String]

        init(items: [String: SlotDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SlotDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SlotDraft) {
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

        func list() -> [SlotDraft] {
            var out: [SlotDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySlotDraftStore() -> any SlotDraftStore {
        return MemorySlotDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSlotDraftStore: SlotDraftStore {
        var inner: MemorySlotDraftStore
        var cache: TTLCache<SlotDraft>
        var hits: Int
        var misses: Int

        init(inner: MemorySlotDraftStore, cache: TTLCache<SlotDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SlotDraft? {
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

        func save(_ item: SlotDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SlotDraft] {
            return inner.list()
        }
    }

    static func newCachedSlotDraftStore(_ inner: MemorySlotDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SlotDraftStore {
        return CachedSlotDraftStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects slot drafts. Empty fields match all.
    final class SlotDraftQuery {
        var locale: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SlotDraft) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [SlotDraft]) -> [SlotDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SlotDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSlotDrafts(_ store: any SlotDraftStore, query: SlotDraftQuery) -> [SlotDraft] {
        return query.apply(store.list())
    }
}
