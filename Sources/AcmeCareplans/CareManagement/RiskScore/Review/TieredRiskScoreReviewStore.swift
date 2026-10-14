import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps tiered risk score reviews by code.
    protocol TieredRiskScoreReviewStore {
        func find(_ code: String) -> TieredRiskScoreReview?
        func save(_ item: TieredRiskScoreReview)
        func remove(_ code: String) -> Bool
        func list() -> [TieredRiskScoreReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredRiskScoreReviewStore: TieredRiskScoreReviewStore {
        var items: [String: TieredRiskScoreReview]
        var order: [String]

        init(items: [String: TieredRiskScoreReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredRiskScoreReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredRiskScoreReview) {
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

        func list() -> [TieredRiskScoreReview] {
            var out: [TieredRiskScoreReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredRiskScoreReviewStore() -> any TieredRiskScoreReviewStore {
        return MemoryTieredRiskScoreReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredRiskScoreReviewStore: TieredRiskScoreReviewStore {
        var inner: MemoryTieredRiskScoreReviewStore
        var cache: TTLCache<TieredRiskScoreReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredRiskScoreReviewStore, cache: TTLCache<TieredRiskScoreReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredRiskScoreReview? {
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

        func save(_ item: TieredRiskScoreReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredRiskScoreReview] {
            return inner.list()
        }
    }

    static func newCachedTieredRiskScoreReviewStore(_ inner: MemoryTieredRiskScoreReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredRiskScoreReviewStore {
        return CachedTieredRiskScoreReviewStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered risk score reviews. Empty fields match all.
    final class TieredRiskScoreReviewQuery {
        var unit: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMargin: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredRiskScoreReview) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredRiskScoreReview]) -> [TieredRiskScoreReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredRiskScoreReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredRiskScoreReviews(_ store: any TieredRiskScoreReviewStore, query: TieredRiskScoreReviewQuery) -> [TieredRiskScoreReview] {
        return query.apply(store.list())
    }
}
