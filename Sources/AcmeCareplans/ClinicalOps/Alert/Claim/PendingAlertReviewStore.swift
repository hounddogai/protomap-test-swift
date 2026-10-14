import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps pending alert reviews by code.
    protocol PendingAlertReviewStore {
        func find(_ code: String) -> PendingAlertReview?
        func save(_ item: PendingAlertReview)
        func remove(_ code: String) -> Bool
        func list() -> [PendingAlertReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingAlertReviewStore: PendingAlertReviewStore {
        var items: [String: PendingAlertReview]
        var order: [String]

        init(items: [String: PendingAlertReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingAlertReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingAlertReview) {
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

        func list() -> [PendingAlertReview] {
            var out: [PendingAlertReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingAlertReviewStore() -> any PendingAlertReviewStore {
        return MemoryPendingAlertReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingAlertReviewStore: PendingAlertReviewStore {
        var inner: MemoryPendingAlertReviewStore
        var cache: TTLCache<PendingAlertReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingAlertReviewStore, cache: TTLCache<PendingAlertReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingAlertReview? {
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

        func save(_ item: PendingAlertReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingAlertReview] {
            return inner.list()
        }
    }

    static func newCachedPendingAlertReviewStore(_ inner: MemoryPendingAlertReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingAlertReviewStore {
        return CachedPendingAlertReviewStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending alert reviews. Empty fields match all.
    final class PendingAlertReviewQuery {
        var category: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingAlertReview) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingAlertReview]) -> [PendingAlertReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingAlertReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingAlertReviews(_ store: any PendingAlertReviewStore, query: PendingAlertReviewQuery) -> [PendingAlertReview] {
        return query.apply(store.list())
    }
}
