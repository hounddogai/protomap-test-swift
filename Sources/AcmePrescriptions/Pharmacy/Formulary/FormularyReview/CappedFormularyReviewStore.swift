import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps capped formulary reviews by code.
    protocol CappedFormularyReviewStore {
        func find(_ code: String) -> CappedFormularyReview?
        func save(_ item: CappedFormularyReview)
        func remove(_ code: String) -> Bool
        func list() -> [CappedFormularyReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedFormularyReviewStore: CappedFormularyReviewStore {
        var items: [String: CappedFormularyReview]
        var order: [String]

        init(items: [String: CappedFormularyReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedFormularyReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedFormularyReview) {
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

        func list() -> [CappedFormularyReview] {
            var out: [CappedFormularyReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedFormularyReviewStore() -> any CappedFormularyReviewStore {
        return MemoryCappedFormularyReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedFormularyReviewStore: CappedFormularyReviewStore {
        var inner: MemoryCappedFormularyReviewStore
        var cache: TTLCache<CappedFormularyReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedFormularyReviewStore, cache: TTLCache<CappedFormularyReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedFormularyReview? {
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

        func save(_ item: CappedFormularyReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedFormularyReview] {
            return inner.list()
        }
    }

    static func newCachedCappedFormularyReviewStore(_ inner: MemoryCappedFormularyReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedFormularyReviewStore {
        return CachedCappedFormularyReviewStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped formulary reviews. Empty fields match all.
    final class CappedFormularyReviewQuery {
        var title: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedFormularyReview) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedFormularyReview]) -> [CappedFormularyReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedFormularyReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedFormularyReviews(_ store: any CappedFormularyReviewStore, query: CappedFormularyReviewQuery) -> [CappedFormularyReview] {
        return query.apply(store.list())
    }
}
