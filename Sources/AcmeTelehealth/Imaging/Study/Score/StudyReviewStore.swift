import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study reviews by code.
    protocol StudyReviewStore {
        func find(_ code: String) -> StudyReview?
        func save(_ item: StudyReview)
        func remove(_ code: String) -> Bool
        func list() -> [StudyReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyReviewStore: StudyReviewStore {
        var items: [String: StudyReview]
        var order: [String]

        init(items: [String: StudyReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyReview) {
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

        func list() -> [StudyReview] {
            var out: [StudyReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyReviewStore() -> any StudyReviewStore {
        return MemoryStudyReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyReviewStore: StudyReviewStore {
        var inner: MemoryStudyReviewStore
        var cache: TTLCache<StudyReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyReviewStore, cache: TTLCache<StudyReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyReview? {
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

        func save(_ item: StudyReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyReview] {
            return inner.list()
        }
    }

    static func newCachedStudyReviewStore(_ inner: MemoryStudyReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyReviewStore {
        return CachedStudyReviewStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study reviews. Empty fields match all.
    final class StudyReviewQuery {
        var unit: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudyReview) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StudyReview]) -> [StudyReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyReviews(_ store: any StudyReviewStore, query: StudyReviewQuery) -> [StudyReview] {
        return query.apply(store.list())
    }
}
