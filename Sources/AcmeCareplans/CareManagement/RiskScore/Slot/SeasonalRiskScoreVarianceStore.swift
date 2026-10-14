import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps seasonal risk score variances by code.
    protocol SeasonalRiskScoreVarianceStore {
        func find(_ code: String) -> SeasonalRiskScoreVariance?
        func save(_ item: SeasonalRiskScoreVariance)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalRiskScoreVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalRiskScoreVarianceStore: SeasonalRiskScoreVarianceStore {
        var items: [String: SeasonalRiskScoreVariance]
        var order: [String]

        init(items: [String: SeasonalRiskScoreVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalRiskScoreVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalRiskScoreVariance) {
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

        func list() -> [SeasonalRiskScoreVariance] {
            var out: [SeasonalRiskScoreVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalRiskScoreVarianceStore() -> any SeasonalRiskScoreVarianceStore {
        return MemorySeasonalRiskScoreVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalRiskScoreVarianceStore: SeasonalRiskScoreVarianceStore {
        var inner: MemorySeasonalRiskScoreVarianceStore
        var cache: TTLCache<SeasonalRiskScoreVariance>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalRiskScoreVarianceStore, cache: TTLCache<SeasonalRiskScoreVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalRiskScoreVariance? {
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

        func save(_ item: SeasonalRiskScoreVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalRiskScoreVariance] {
            return inner.list()
        }
    }

    static func newCachedSeasonalRiskScoreVarianceStore(_ inner: MemorySeasonalRiskScoreVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalRiskScoreVarianceStore {
        return CachedSeasonalRiskScoreVarianceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal risk score variances. Empty fields match all.
    final class SeasonalRiskScoreVarianceQuery {
        var country: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minVersion: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalRiskScoreVariance) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalRiskScoreVariance]) -> [SeasonalRiskScoreVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalRiskScoreVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalRiskScoreVariances(_ store: any SeasonalRiskScoreVarianceStore, query: SeasonalRiskScoreVarianceQuery) -> [SeasonalRiskScoreVariance] {
        return query.apply(store.list())
    }
}
