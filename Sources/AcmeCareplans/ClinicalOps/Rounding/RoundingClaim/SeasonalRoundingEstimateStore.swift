import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps seasonal rounding estimates by code.
    protocol SeasonalRoundingEstimateStore {
        func find(_ code: String) -> SeasonalRoundingEstimate?
        func save(_ item: SeasonalRoundingEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalRoundingEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalRoundingEstimateStore: SeasonalRoundingEstimateStore {
        var items: [String: SeasonalRoundingEstimate]
        var order: [String]

        init(items: [String: SeasonalRoundingEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalRoundingEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalRoundingEstimate) {
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

        func list() -> [SeasonalRoundingEstimate] {
            var out: [SeasonalRoundingEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalRoundingEstimateStore() -> any SeasonalRoundingEstimateStore {
        return MemorySeasonalRoundingEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalRoundingEstimateStore: SeasonalRoundingEstimateStore {
        var inner: MemorySeasonalRoundingEstimateStore
        var cache: TTLCache<SeasonalRoundingEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalRoundingEstimateStore, cache: TTLCache<SeasonalRoundingEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalRoundingEstimate? {
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

        func save(_ item: SeasonalRoundingEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalRoundingEstimate] {
            return inner.list()
        }
    }

    static func newCachedSeasonalRoundingEstimateStore(_ inner: MemorySeasonalRoundingEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalRoundingEstimateStore {
        return CachedSeasonalRoundingEstimateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal rounding estimates. Empty fields match all.
    final class SeasonalRoundingEstimateQuery {
        var source: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalRoundingEstimate) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [SeasonalRoundingEstimate]) -> [SeasonalRoundingEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalRoundingEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalRoundingEstimates(_ store: any SeasonalRoundingEstimateStore, query: SeasonalRoundingEstimateQuery) -> [SeasonalRoundingEstimate] {
        return query.apply(store.list())
    }
}
