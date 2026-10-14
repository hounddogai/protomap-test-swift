import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps primary study reviews by code.
    protocol PrimaryStudyReviewStore {
        func find(_ code: String) -> PrimaryStudyReview?
        func save(_ item: PrimaryStudyReview)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryStudyReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryStudyReviewStore: PrimaryStudyReviewStore {
        var items: [String: PrimaryStudyReview]
        var order: [String]

        init(items: [String: PrimaryStudyReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryStudyReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryStudyReview) {
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

        func list() -> [PrimaryStudyReview] {
            var out: [PrimaryStudyReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryStudyReviewStore() -> any PrimaryStudyReviewStore {
        return MemoryPrimaryStudyReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryStudyReviewStore: PrimaryStudyReviewStore {
        var inner: MemoryPrimaryStudyReviewStore
        var cache: TTLCache<PrimaryStudyReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryStudyReviewStore, cache: TTLCache<PrimaryStudyReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryStudyReview? {
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

        func save(_ item: PrimaryStudyReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryStudyReview] {
            return inner.list()
        }
    }

    static func newCachedPrimaryStudyReviewStore(_ inner: MemoryPrimaryStudyReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryStudyReviewStore {
        return CachedPrimaryStudyReviewStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary study reviews. Empty fields match all.
    final class PrimaryStudyReviewQuery {
        var source: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryStudyReview) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [PrimaryStudyReview]) -> [PrimaryStudyReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryStudyReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryStudyReviews(_ store: any PrimaryStudyReviewStore, query: PrimaryStudyReviewQuery) -> [PrimaryStudyReview] {
        return query.apply(store.list())
    }
}
