import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps global bed board drafts by code.
    protocol GlobalBedBoardDraftStore {
        func find(_ code: String) -> GlobalBedBoardDraft?
        func save(_ item: GlobalBedBoardDraft)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalBedBoardDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalBedBoardDraftStore: GlobalBedBoardDraftStore {
        var items: [String: GlobalBedBoardDraft]
        var order: [String]

        init(items: [String: GlobalBedBoardDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalBedBoardDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalBedBoardDraft) {
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

        func list() -> [GlobalBedBoardDraft] {
            var out: [GlobalBedBoardDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalBedBoardDraftStore() -> any GlobalBedBoardDraftStore {
        return MemoryGlobalBedBoardDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalBedBoardDraftStore: GlobalBedBoardDraftStore {
        var inner: MemoryGlobalBedBoardDraftStore
        var cache: TTLCache<GlobalBedBoardDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalBedBoardDraftStore, cache: TTLCache<GlobalBedBoardDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalBedBoardDraft? {
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

        func save(_ item: GlobalBedBoardDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalBedBoardDraft] {
            return inner.list()
        }
    }

    static func newCachedGlobalBedBoardDraftStore(_ inner: MemoryGlobalBedBoardDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalBedBoardDraftStore {
        return CachedGlobalBedBoardDraftStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global bed board drafts. Empty fields match all.
    final class GlobalBedBoardDraftQuery {
        var label: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMargin: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalBedBoardDraft) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalBedBoardDraft]) -> [GlobalBedBoardDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalBedBoardDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalBedBoardDrafts(_ store: any GlobalBedBoardDraftStore, query: GlobalBedBoardDraftQuery) -> [GlobalBedBoardDraft] {
        return query.apply(store.list())
    }
}
