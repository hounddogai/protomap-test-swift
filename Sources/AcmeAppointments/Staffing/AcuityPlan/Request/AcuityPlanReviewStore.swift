import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan reviews by code.
    protocol AcuityPlanReviewStore {
        func find(_ code: String) -> AcuityPlanReview?
        func save(_ item: AcuityPlanReview)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanReviewStore: AcuityPlanReviewStore {
        var items: [String: AcuityPlanReview]
        var order: [String]

        init(items: [String: AcuityPlanReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanReview) {
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

        func list() -> [AcuityPlanReview] {
            var out: [AcuityPlanReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanReviewStore() -> any AcuityPlanReviewStore {
        return MemoryAcuityPlanReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanReviewStore: AcuityPlanReviewStore {
        var inner: MemoryAcuityPlanReviewStore
        var cache: TTLCache<AcuityPlanReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanReviewStore, cache: TTLCache<AcuityPlanReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanReview? {
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

        func save(_ item: AcuityPlanReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanReview] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanReviewStore(_ inner: MemoryAcuityPlanReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanReviewStore {
        return CachedAcuityPlanReviewStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan reviews. Empty fields match all.
    final class AcuityPlanReviewQuery {
        var name: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanReview) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AcuityPlanReview]) -> [AcuityPlanReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanReviews(_ store: any AcuityPlanReviewStore, query: AcuityPlanReviewQuery) -> [AcuityPlanReview] {
        return query.apply(store.list())
    }
}
