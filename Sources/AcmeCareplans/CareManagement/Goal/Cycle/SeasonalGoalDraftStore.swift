import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps seasonal goal drafts by code.
    protocol SeasonalGoalDraftStore {
        func find(_ code: String) -> SeasonalGoalDraft?
        func save(_ item: SeasonalGoalDraft)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalGoalDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalGoalDraftStore: SeasonalGoalDraftStore {
        var items: [String: SeasonalGoalDraft]
        var order: [String]

        init(items: [String: SeasonalGoalDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalGoalDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalGoalDraft) {
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

        func list() -> [SeasonalGoalDraft] {
            var out: [SeasonalGoalDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalGoalDraftStore() -> any SeasonalGoalDraftStore {
        return MemorySeasonalGoalDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalGoalDraftStore: SeasonalGoalDraftStore {
        var inner: MemorySeasonalGoalDraftStore
        var cache: TTLCache<SeasonalGoalDraft>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalGoalDraftStore, cache: TTLCache<SeasonalGoalDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalGoalDraft? {
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

        func save(_ item: SeasonalGoalDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalGoalDraft] {
            return inner.list()
        }
    }

    static func newCachedSeasonalGoalDraftStore(_ inner: MemorySeasonalGoalDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalGoalDraftStore {
        return CachedSeasonalGoalDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal goal drafts. Empty fields match all.
    final class SeasonalGoalDraftQuery {
        var label: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalGoalDraft) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalGoalDraft]) -> [SeasonalGoalDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalGoalDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalGoalDrafts(_ store: any SeasonalGoalDraftStore, query: SeasonalGoalDraftQuery) -> [SeasonalGoalDraft] {
        return query.apply(store.list())
    }
}
