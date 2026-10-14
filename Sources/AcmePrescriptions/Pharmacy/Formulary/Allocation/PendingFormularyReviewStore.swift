import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps pending formulary reviews by code.
    protocol PendingFormularyReviewStore {
        func find(_ code: String) -> PendingFormularyReview?
        func save(_ item: PendingFormularyReview)
        func remove(_ code: String) -> Bool
        func list() -> [PendingFormularyReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingFormularyReviewStore: PendingFormularyReviewStore {
        var items: [String: PendingFormularyReview]
        var order: [String]

        init(items: [String: PendingFormularyReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingFormularyReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingFormularyReview) {
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

        func list() -> [PendingFormularyReview] {
            var out: [PendingFormularyReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingFormularyReviewStore() -> any PendingFormularyReviewStore {
        return MemoryPendingFormularyReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingFormularyReviewStore: PendingFormularyReviewStore {
        var inner: MemoryPendingFormularyReviewStore
        var cache: TTLCache<PendingFormularyReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingFormularyReviewStore, cache: TTLCache<PendingFormularyReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingFormularyReview? {
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

        func save(_ item: PendingFormularyReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingFormularyReview] {
            return inner.list()
        }
    }

    static func newCachedPendingFormularyReviewStore(_ inner: MemoryPendingFormularyReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingFormularyReviewStore {
        return CachedPendingFormularyReviewStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending formulary reviews. Empty fields match all.
    final class PendingFormularyReviewQuery {
        var name: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingFormularyReview) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingFormularyReview]) -> [PendingFormularyReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingFormularyReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingFormularyReviews(_ store: any PendingFormularyReviewStore, query: PendingFormularyReviewQuery) -> [PendingFormularyReview] {
        return query.apply(store.list())
    }
}
