import AcmePlatform
import Foundation

extension Consent {
    /// Keeps seasonal revocation policies by code.
    protocol SeasonalRevocationPolicyStore {
        func find(_ code: String) -> SeasonalRevocationPolicy?
        func save(_ item: SeasonalRevocationPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalRevocationPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalRevocationPolicyStore: SeasonalRevocationPolicyStore {
        var items: [String: SeasonalRevocationPolicy]
        var order: [String]

        init(items: [String: SeasonalRevocationPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalRevocationPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalRevocationPolicy) {
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

        func list() -> [SeasonalRevocationPolicy] {
            var out: [SeasonalRevocationPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalRevocationPolicyStore() -> any SeasonalRevocationPolicyStore {
        return MemorySeasonalRevocationPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalRevocationPolicyStore: SeasonalRevocationPolicyStore {
        var inner: MemorySeasonalRevocationPolicyStore
        var cache: TTLCache<SeasonalRevocationPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalRevocationPolicyStore, cache: TTLCache<SeasonalRevocationPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalRevocationPolicy? {
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

        func save(_ item: SeasonalRevocationPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalRevocationPolicy] {
            return inner.list()
        }
    }

    static func newCachedSeasonalRevocationPolicyStore(_ inner: MemorySeasonalRevocationPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalRevocationPolicyStore {
        return CachedSeasonalRevocationPolicyStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal revocation policies. Empty fields match all.
    final class SeasonalRevocationPolicyQuery {
        var name: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalRevocationPolicy) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [SeasonalRevocationPolicy]) -> [SeasonalRevocationPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalRevocationPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalRevocationPolicies(_ store: any SeasonalRevocationPolicyStore, query: SeasonalRevocationPolicyQuery) -> [SeasonalRevocationPolicy] {
        return query.apply(store.list())
    }
}
