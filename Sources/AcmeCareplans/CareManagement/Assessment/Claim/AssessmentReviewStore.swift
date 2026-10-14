import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment reviews by code.
    protocol AssessmentReviewStore {
        func find(_ code: String) -> AssessmentReview?
        func save(_ item: AssessmentReview)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentReviewStore: AssessmentReviewStore {
        var items: [String: AssessmentReview]
        var order: [String]

        init(items: [String: AssessmentReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentReview) {
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

        func list() -> [AssessmentReview] {
            var out: [AssessmentReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentReviewStore() -> any AssessmentReviewStore {
        return MemoryAssessmentReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentReviewStore: AssessmentReviewStore {
        var inner: MemoryAssessmentReviewStore
        var cache: TTLCache<AssessmentReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentReviewStore, cache: TTLCache<AssessmentReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentReview? {
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

        func save(_ item: AssessmentReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentReview] {
            return inner.list()
        }
    }

    static func newCachedAssessmentReviewStore(_ inner: MemoryAssessmentReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentReviewStore {
        return CachedAssessmentReviewStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment reviews. Empty fields match all.
    final class AssessmentReviewQuery {
        var ward: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentReview) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AssessmentReview]) -> [AssessmentReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentReviews(_ store: any AssessmentReviewStore, query: AssessmentReviewQuery) -> [AssessmentReview] {
        return query.apply(store.list())
    }
}
