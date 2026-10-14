import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal reviews by code.
    protocol GoalReviewStore {
        func find(_ code: String) -> GoalReview?
        func save(_ item: GoalReview)
        func remove(_ code: String) -> Bool
        func list() -> [GoalReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalReviewStore: GoalReviewStore {
        var items: [String: GoalReview]
        var order: [String]

        init(items: [String: GoalReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalReview) {
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

        func list() -> [GoalReview] {
            var out: [GoalReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalReviewStore() -> any GoalReviewStore {
        return MemoryGoalReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalReviewStore: GoalReviewStore {
        var inner: MemoryGoalReviewStore
        var cache: TTLCache<GoalReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalReviewStore, cache: TTLCache<GoalReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalReview? {
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

        func save(_ item: GoalReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalReview] {
            return inner.list()
        }
    }

    static func newCachedGoalReviewStore(_ inner: MemoryGoalReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalReviewStore {
        return CachedGoalReviewStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal reviews. Empty fields match all.
    final class GoalReviewQuery {
        var segment: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minRevision: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalReview) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GoalReview]) -> [GoalReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalReviews(_ store: any GoalReviewStore, query: GoalReviewQuery) -> [GoalReview] {
        return query.apply(store.list())
    }
}
