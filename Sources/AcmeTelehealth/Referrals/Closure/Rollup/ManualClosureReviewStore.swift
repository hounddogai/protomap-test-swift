import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps manual closure reviews by code.
    protocol ManualClosureReviewStore {
        func find(_ code: String) -> ManualClosureReview?
        func save(_ item: ManualClosureReview)
        func remove(_ code: String) -> Bool
        func list() -> [ManualClosureReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualClosureReviewStore: ManualClosureReviewStore {
        var items: [String: ManualClosureReview]
        var order: [String]

        init(items: [String: ManualClosureReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualClosureReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualClosureReview) {
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

        func list() -> [ManualClosureReview] {
            var out: [ManualClosureReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualClosureReviewStore() -> any ManualClosureReviewStore {
        return MemoryManualClosureReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualClosureReviewStore: ManualClosureReviewStore {
        var inner: MemoryManualClosureReviewStore
        var cache: TTLCache<ManualClosureReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualClosureReviewStore, cache: TTLCache<ManualClosureReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualClosureReview? {
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

        func save(_ item: ManualClosureReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualClosureReview] {
            return inner.list()
        }
    }

    static func newCachedManualClosureReviewStore(_ inner: MemoryManualClosureReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualClosureReviewStore {
        return CachedManualClosureReviewStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual closure reviews. Empty fields match all.
    final class ManualClosureReviewQuery {
        var name: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualClosureReview) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualClosureReview]) -> [ManualClosureReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualClosureReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualClosureReviews(_ store: any ManualClosureReviewStore, query: ManualClosureReviewQuery) -> [ManualClosureReview] {
        return query.apply(store.list())
    }
}
