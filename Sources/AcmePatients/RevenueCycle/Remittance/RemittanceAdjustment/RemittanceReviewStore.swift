import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance reviews by code.
    protocol RemittanceReviewStore {
        func find(_ code: String) -> RemittanceReview?
        func save(_ item: RemittanceReview)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceReviewStore: RemittanceReviewStore {
        var items: [String: RemittanceReview]
        var order: [String]

        init(items: [String: RemittanceReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceReview) {
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

        func list() -> [RemittanceReview] {
            var out: [RemittanceReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceReviewStore() -> any RemittanceReviewStore {
        return MemoryRemittanceReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceReviewStore: RemittanceReviewStore {
        var inner: MemoryRemittanceReviewStore
        var cache: TTLCache<RemittanceReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceReviewStore, cache: TTLCache<RemittanceReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceReview? {
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

        func save(_ item: RemittanceReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceReview] {
            return inner.list()
        }
    }

    static func newCachedRemittanceReviewStore(_ inner: MemoryRemittanceReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceReviewStore {
        return CachedRemittanceReviewStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance reviews. Empty fields match all.
    final class RemittanceReviewQuery {
        var title: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMargin: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceReview) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittanceReview]) -> [RemittanceReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceReviews(_ store: any RemittanceReviewStore, query: RemittanceReviewQuery) -> [RemittanceReview] {
        return query.apply(store.list())
    }
}
