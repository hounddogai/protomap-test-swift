import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial reviews by code.
    protocol DenialReviewStore {
        func find(_ code: String) -> DenialReview?
        func save(_ item: DenialReview)
        func remove(_ code: String) -> Bool
        func list() -> [DenialReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialReviewStore: DenialReviewStore {
        var items: [String: DenialReview]
        var order: [String]

        init(items: [String: DenialReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialReview) {
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

        func list() -> [DenialReview] {
            var out: [DenialReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialReviewStore() -> any DenialReviewStore {
        return MemoryDenialReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialReviewStore: DenialReviewStore {
        var inner: MemoryDenialReviewStore
        var cache: TTLCache<DenialReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialReviewStore, cache: TTLCache<DenialReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialReview? {
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

        func save(_ item: DenialReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialReview] {
            return inner.list()
        }
    }

    static func newCachedDenialReviewStore(_ inner: MemoryDenialReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialReviewStore {
        return CachedDenialReviewStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial reviews. Empty fields match all.
    final class DenialReviewQuery {
        var name: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialReview) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [DenialReview]) -> [DenialReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialReviews(_ store: any DenialReviewStore, query: DenialReviewQuery) -> [DenialReview] {
        return query.apply(store.list())
    }
}
