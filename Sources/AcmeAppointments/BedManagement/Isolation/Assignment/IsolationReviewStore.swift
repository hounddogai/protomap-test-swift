import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation reviews by code.
    protocol IsolationReviewStore {
        func find(_ code: String) -> IsolationReview?
        func save(_ item: IsolationReview)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationReviewStore: IsolationReviewStore {
        var items: [String: IsolationReview]
        var order: [String]

        init(items: [String: IsolationReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationReview) {
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

        func list() -> [IsolationReview] {
            var out: [IsolationReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationReviewStore() -> any IsolationReviewStore {
        return MemoryIsolationReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationReviewStore: IsolationReviewStore {
        var inner: MemoryIsolationReviewStore
        var cache: TTLCache<IsolationReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationReviewStore, cache: TTLCache<IsolationReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationReview? {
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

        func save(_ item: IsolationReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationReview] {
            return inner.list()
        }
    }

    static func newCachedIsolationReviewStore(_ inner: MemoryIsolationReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationReviewStore {
        return CachedIsolationReviewStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation reviews. Empty fields match all.
    final class IsolationReviewQuery {
        var title: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationReview) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [IsolationReview]) -> [IsolationReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationReviews(_ store: any IsolationReviewStore, query: IsolationReviewQuery) -> [IsolationReview] {
        return query.apply(store.list())
    }
}
