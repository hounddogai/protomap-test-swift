import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered study reviews by code.
    protocol TieredStudyReviewStore {
        func find(_ code: String) -> TieredStudyReview?
        func save(_ item: TieredStudyReview)
        func remove(_ code: String) -> Bool
        func list() -> [TieredStudyReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredStudyReviewStore: TieredStudyReviewStore {
        var items: [String: TieredStudyReview]
        var order: [String]

        init(items: [String: TieredStudyReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredStudyReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredStudyReview) {
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

        func list() -> [TieredStudyReview] {
            var out: [TieredStudyReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredStudyReviewStore() -> any TieredStudyReviewStore {
        return MemoryTieredStudyReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredStudyReviewStore: TieredStudyReviewStore {
        var inner: MemoryTieredStudyReviewStore
        var cache: TTLCache<TieredStudyReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredStudyReviewStore, cache: TTLCache<TieredStudyReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredStudyReview? {
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

        func save(_ item: TieredStudyReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredStudyReview] {
            return inner.list()
        }
    }

    static func newCachedTieredStudyReviewStore(_ inner: MemoryTieredStudyReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredStudyReviewStore {
        return CachedTieredStudyReviewStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered study reviews. Empty fields match all.
    final class TieredStudyReviewQuery {
        var unit: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minBudget: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredStudyReview) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [TieredStudyReview]) -> [TieredStudyReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredStudyReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredStudyReviews(_ store: any TieredStudyReviewStore, query: TieredStudyReviewQuery) -> [TieredStudyReview] {
        return query.apply(store.list())
    }
}
