import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps capped isolation reviews by code.
    protocol CappedIsolationReviewStore {
        func find(_ code: String) -> CappedIsolationReview?
        func save(_ item: CappedIsolationReview)
        func remove(_ code: String) -> Bool
        func list() -> [CappedIsolationReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedIsolationReviewStore: CappedIsolationReviewStore {
        var items: [String: CappedIsolationReview]
        var order: [String]

        init(items: [String: CappedIsolationReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedIsolationReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedIsolationReview) {
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

        func list() -> [CappedIsolationReview] {
            var out: [CappedIsolationReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedIsolationReviewStore() -> any CappedIsolationReviewStore {
        return MemoryCappedIsolationReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedIsolationReviewStore: CappedIsolationReviewStore {
        var inner: MemoryCappedIsolationReviewStore
        var cache: TTLCache<CappedIsolationReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedIsolationReviewStore, cache: TTLCache<CappedIsolationReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedIsolationReview? {
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

        func save(_ item: CappedIsolationReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedIsolationReview] {
            return inner.list()
        }
    }

    static func newCachedCappedIsolationReviewStore(_ inner: MemoryCappedIsolationReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedIsolationReviewStore {
        return CachedCappedIsolationReviewStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped isolation reviews. Empty fields match all.
    final class CappedIsolationReviewQuery {
        var name: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minScore: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedIsolationReview) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedIsolationReview]) -> [CappedIsolationReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedIsolationReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedIsolationReviews(_ store: any CappedIsolationReviewStore, query: CappedIsolationReviewQuery) -> [CappedIsolationReview] {
        return query.apply(store.list())
    }
}
