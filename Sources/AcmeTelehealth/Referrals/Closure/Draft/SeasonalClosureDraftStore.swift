import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps seasonal closure drafts by code.
    protocol SeasonalClosureDraftStore {
        func find(_ code: String) -> SeasonalClosureDraft?
        func save(_ item: SeasonalClosureDraft)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalClosureDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalClosureDraftStore: SeasonalClosureDraftStore {
        var items: [String: SeasonalClosureDraft]
        var order: [String]

        init(items: [String: SeasonalClosureDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalClosureDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalClosureDraft) {
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

        func list() -> [SeasonalClosureDraft] {
            var out: [SeasonalClosureDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalClosureDraftStore() -> any SeasonalClosureDraftStore {
        return MemorySeasonalClosureDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalClosureDraftStore: SeasonalClosureDraftStore {
        var inner: MemorySeasonalClosureDraftStore
        var cache: TTLCache<SeasonalClosureDraft>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalClosureDraftStore, cache: TTLCache<SeasonalClosureDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalClosureDraft? {
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

        func save(_ item: SeasonalClosureDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalClosureDraft] {
            return inner.list()
        }
    }

    static func newCachedSeasonalClosureDraftStore(_ inner: MemorySeasonalClosureDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalClosureDraftStore {
        return CachedSeasonalClosureDraftStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal closure drafts. Empty fields match all.
    final class SeasonalClosureDraftQuery {
        var title: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minBudget: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalClosureDraft) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalClosureDraft]) -> [SeasonalClosureDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalClosureDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalClosureDrafts(_ store: any SeasonalClosureDraftStore, query: SeasonalClosureDraftQuery) -> [SeasonalClosureDraft] {
        return query.apply(store.list())
    }
}
