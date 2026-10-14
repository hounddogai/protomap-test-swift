import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps seasonal care gap tiers by code.
    protocol SeasonalCareGapTierStore {
        func find(_ code: String) -> SeasonalCareGapTier?
        func save(_ item: SeasonalCareGapTier)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalCareGapTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalCareGapTierStore: SeasonalCareGapTierStore {
        var items: [String: SeasonalCareGapTier]
        var order: [String]

        init(items: [String: SeasonalCareGapTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalCareGapTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalCareGapTier) {
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

        func list() -> [SeasonalCareGapTier] {
            var out: [SeasonalCareGapTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalCareGapTierStore() -> any SeasonalCareGapTierStore {
        return MemorySeasonalCareGapTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalCareGapTierStore: SeasonalCareGapTierStore {
        var inner: MemorySeasonalCareGapTierStore
        var cache: TTLCache<SeasonalCareGapTier>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalCareGapTierStore, cache: TTLCache<SeasonalCareGapTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalCareGapTier? {
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

        func save(_ item: SeasonalCareGapTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalCareGapTier] {
            return inner.list()
        }
    }

    static func newCachedSeasonalCareGapTierStore(_ inner: MemorySeasonalCareGapTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalCareGapTierStore {
        return CachedSeasonalCareGapTierStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal care gap tiers. Empty fields match all.
    final class SeasonalCareGapTierQuery {
        var unit: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minScore: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalCareGapTier) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalCareGapTier]) -> [SeasonalCareGapTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalCareGapTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalCareGapTiers(_ store: any SeasonalCareGapTierStore, query: SeasonalCareGapTierQuery) -> [SeasonalCareGapTier] {
        return query.apply(store.list())
    }
}
