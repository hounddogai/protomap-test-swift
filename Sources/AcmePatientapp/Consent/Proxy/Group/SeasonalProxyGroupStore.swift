import AcmePlatform
import Foundation

extension Consent {
    /// Keeps seasonal proxy groups by code.
    protocol SeasonalProxyGroupStore {
        func find(_ code: String) -> SeasonalProxyGroup?
        func save(_ item: SeasonalProxyGroup)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalProxyGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalProxyGroupStore: SeasonalProxyGroupStore {
        var items: [String: SeasonalProxyGroup]
        var order: [String]

        init(items: [String: SeasonalProxyGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalProxyGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalProxyGroup) {
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

        func list() -> [SeasonalProxyGroup] {
            var out: [SeasonalProxyGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalProxyGroupStore() -> any SeasonalProxyGroupStore {
        return MemorySeasonalProxyGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalProxyGroupStore: SeasonalProxyGroupStore {
        var inner: MemorySeasonalProxyGroupStore
        var cache: TTLCache<SeasonalProxyGroup>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalProxyGroupStore, cache: TTLCache<SeasonalProxyGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalProxyGroup? {
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

        func save(_ item: SeasonalProxyGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalProxyGroup] {
            return inner.list()
        }
    }

    static func newCachedSeasonalProxyGroupStore(_ inner: MemorySeasonalProxyGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalProxyGroupStore {
        return CachedSeasonalProxyGroupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal proxy groups. Empty fields match all.
    final class SeasonalProxyGroupQuery {
        var title: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalProxyGroup) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [SeasonalProxyGroup]) -> [SeasonalProxyGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalProxyGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalProxyGroups(_ store: any SeasonalProxyGroupStore, query: SeasonalProxyGroupQuery) -> [SeasonalProxyGroup] {
        return query.apply(store.list())
    }
}
