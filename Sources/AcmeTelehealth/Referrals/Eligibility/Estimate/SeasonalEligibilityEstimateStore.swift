import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps seasonal eligibility estimates by code.
    protocol SeasonalEligibilityEstimateStore {
        func find(_ code: String) -> SeasonalEligibilityEstimate?
        func save(_ item: SeasonalEligibilityEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalEligibilityEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalEligibilityEstimateStore: SeasonalEligibilityEstimateStore {
        var items: [String: SeasonalEligibilityEstimate]
        var order: [String]

        init(items: [String: SeasonalEligibilityEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalEligibilityEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalEligibilityEstimate) {
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

        func list() -> [SeasonalEligibilityEstimate] {
            var out: [SeasonalEligibilityEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalEligibilityEstimateStore() -> any SeasonalEligibilityEstimateStore {
        return MemorySeasonalEligibilityEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalEligibilityEstimateStore: SeasonalEligibilityEstimateStore {
        var inner: MemorySeasonalEligibilityEstimateStore
        var cache: TTLCache<SeasonalEligibilityEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalEligibilityEstimateStore, cache: TTLCache<SeasonalEligibilityEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalEligibilityEstimate? {
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

        func save(_ item: SeasonalEligibilityEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalEligibilityEstimate] {
            return inner.list()
        }
    }

    static func newCachedSeasonalEligibilityEstimateStore(_ inner: MemorySeasonalEligibilityEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalEligibilityEstimateStore {
        return CachedSeasonalEligibilityEstimateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal eligibility estimates. Empty fields match all.
    final class SeasonalEligibilityEstimateQuery {
        var title: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalEligibilityEstimate) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalEligibilityEstimate]) -> [SeasonalEligibilityEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalEligibilityEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalEligibilityEstimates(_ store: any SeasonalEligibilityEstimateStore, query: SeasonalEligibilityEstimateQuery) -> [SeasonalEligibilityEstimate] {
        return query.apply(store.list())
    }
}
