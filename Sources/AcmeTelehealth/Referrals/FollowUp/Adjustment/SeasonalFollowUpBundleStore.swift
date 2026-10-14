import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps seasonal follow up bundles by code.
    protocol SeasonalFollowUpBundleStore {
        func find(_ code: String) -> SeasonalFollowUpBundle?
        func save(_ item: SeasonalFollowUpBundle)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalFollowUpBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalFollowUpBundleStore: SeasonalFollowUpBundleStore {
        var items: [String: SeasonalFollowUpBundle]
        var order: [String]

        init(items: [String: SeasonalFollowUpBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalFollowUpBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalFollowUpBundle) {
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

        func list() -> [SeasonalFollowUpBundle] {
            var out: [SeasonalFollowUpBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalFollowUpBundleStore() -> any SeasonalFollowUpBundleStore {
        return MemorySeasonalFollowUpBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalFollowUpBundleStore: SeasonalFollowUpBundleStore {
        var inner: MemorySeasonalFollowUpBundleStore
        var cache: TTLCache<SeasonalFollowUpBundle>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalFollowUpBundleStore, cache: TTLCache<SeasonalFollowUpBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalFollowUpBundle? {
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

        func save(_ item: SeasonalFollowUpBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalFollowUpBundle] {
            return inner.list()
        }
    }

    static func newCachedSeasonalFollowUpBundleStore(_ inner: MemorySeasonalFollowUpBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalFollowUpBundleStore {
        return CachedSeasonalFollowUpBundleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal follow up bundles. Empty fields match all.
    final class SeasonalFollowUpBundleQuery {
        var locale: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minBudget: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalFollowUpBundle) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [SeasonalFollowUpBundle]) -> [SeasonalFollowUpBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalFollowUpBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalFollowUpBundles(_ store: any SeasonalFollowUpBundleStore, query: SeasonalFollowUpBundleQuery) -> [SeasonalFollowUpBundle] {
        return query.apply(store.list())
    }
}
