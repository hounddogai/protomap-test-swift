import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement reviews by code.
    protocol StatementReviewStore {
        func find(_ code: String) -> StatementReview?
        func save(_ item: StatementReview)
        func remove(_ code: String) -> Bool
        func list() -> [StatementReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementReviewStore: StatementReviewStore {
        var items: [String: StatementReview]
        var order: [String]

        init(items: [String: StatementReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementReview) {
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

        func list() -> [StatementReview] {
            var out: [StatementReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementReviewStore() -> any StatementReviewStore {
        return MemoryStatementReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementReviewStore: StatementReviewStore {
        var inner: MemoryStatementReviewStore
        var cache: TTLCache<StatementReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementReviewStore, cache: TTLCache<StatementReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementReview? {
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

        func save(_ item: StatementReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementReview] {
            return inner.list()
        }
    }

    static func newCachedStatementReviewStore(_ inner: MemoryStatementReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementReviewStore {
        return CachedStatementReviewStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement reviews. Empty fields match all.
    final class StatementReviewQuery {
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

        func matches(_ item: StatementReview) -> Bool {
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

        func apply(_ items: [StatementReview]) -> [StatementReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementReviews(_ store: any StatementReviewStore, query: StatementReviewQuery) -> [StatementReview] {
        return query.apply(store.list())
    }
}
