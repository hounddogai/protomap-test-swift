import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps global assessment reviews by code.
    protocol GlobalAssessmentReviewStore {
        func find(_ code: String) -> GlobalAssessmentReview?
        func save(_ item: GlobalAssessmentReview)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalAssessmentReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalAssessmentReviewStore: GlobalAssessmentReviewStore {
        var items: [String: GlobalAssessmentReview]
        var order: [String]

        init(items: [String: GlobalAssessmentReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalAssessmentReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalAssessmentReview) {
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

        func list() -> [GlobalAssessmentReview] {
            var out: [GlobalAssessmentReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalAssessmentReviewStore() -> any GlobalAssessmentReviewStore {
        return MemoryGlobalAssessmentReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalAssessmentReviewStore: GlobalAssessmentReviewStore {
        var inner: MemoryGlobalAssessmentReviewStore
        var cache: TTLCache<GlobalAssessmentReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalAssessmentReviewStore, cache: TTLCache<GlobalAssessmentReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalAssessmentReview? {
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

        func save(_ item: GlobalAssessmentReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalAssessmentReview] {
            return inner.list()
        }
    }

    static func newCachedGlobalAssessmentReviewStore(_ inner: MemoryGlobalAssessmentReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalAssessmentReviewStore {
        return CachedGlobalAssessmentReviewStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global assessment reviews. Empty fields match all.
    final class GlobalAssessmentReviewQuery {
        var country: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalAssessmentReview) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [GlobalAssessmentReview]) -> [GlobalAssessmentReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalAssessmentReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalAssessmentReviews(_ store: any GlobalAssessmentReviewStore, query: GlobalAssessmentReviewQuery) -> [GlobalAssessmentReview] {
        return query.apply(store.list())
    }
}
