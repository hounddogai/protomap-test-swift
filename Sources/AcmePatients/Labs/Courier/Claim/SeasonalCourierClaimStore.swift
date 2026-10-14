import AcmePlatform
import Foundation

extension Labs {
    /// Keeps seasonal courier claims by code.
    protocol SeasonalCourierClaimStore {
        func find(_ code: String) -> SeasonalCourierClaim?
        func save(_ item: SeasonalCourierClaim)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalCourierClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalCourierClaimStore: SeasonalCourierClaimStore {
        var items: [String: SeasonalCourierClaim]
        var order: [String]

        init(items: [String: SeasonalCourierClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalCourierClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalCourierClaim) {
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

        func list() -> [SeasonalCourierClaim] {
            var out: [SeasonalCourierClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalCourierClaimStore() -> any SeasonalCourierClaimStore {
        return MemorySeasonalCourierClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalCourierClaimStore: SeasonalCourierClaimStore {
        var inner: MemorySeasonalCourierClaimStore
        var cache: TTLCache<SeasonalCourierClaim>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalCourierClaimStore, cache: TTLCache<SeasonalCourierClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalCourierClaim? {
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

        func save(_ item: SeasonalCourierClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalCourierClaim] {
            return inner.list()
        }
    }

    static func newCachedSeasonalCourierClaimStore(_ inner: MemorySeasonalCourierClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalCourierClaimStore {
        return CachedSeasonalCourierClaimStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal courier claims. Empty fields match all.
    final class SeasonalCourierClaimQuery {
        var title: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalCourierClaim) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalCourierClaim]) -> [SeasonalCourierClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalCourierClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalCourierClaims(_ store: any SeasonalCourierClaimStore, query: SeasonalCourierClaimQuery) -> [SeasonalCourierClaim] {
        return query.apply(store.list())
    }
}
