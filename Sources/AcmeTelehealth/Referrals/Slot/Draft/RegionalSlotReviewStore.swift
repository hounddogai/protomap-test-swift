import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps regional slot reviews by code.
    protocol RegionalSlotReviewStore {
        func find(_ code: String) -> RegionalSlotReview?
        func save(_ item: RegionalSlotReview)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalSlotReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalSlotReviewStore: RegionalSlotReviewStore {
        var items: [String: RegionalSlotReview]
        var order: [String]

        init(items: [String: RegionalSlotReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalSlotReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalSlotReview) {
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

        func list() -> [RegionalSlotReview] {
            var out: [RegionalSlotReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalSlotReviewStore() -> any RegionalSlotReviewStore {
        return MemoryRegionalSlotReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalSlotReviewStore: RegionalSlotReviewStore {
        var inner: MemoryRegionalSlotReviewStore
        var cache: TTLCache<RegionalSlotReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalSlotReviewStore, cache: TTLCache<RegionalSlotReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalSlotReview? {
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

        func save(_ item: RegionalSlotReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalSlotReview] {
            return inner.list()
        }
    }

    static func newCachedRegionalSlotReviewStore(_ inner: MemoryRegionalSlotReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalSlotReviewStore {
        return CachedRegionalSlotReviewStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional slot reviews. Empty fields match all.
    final class RegionalSlotReviewQuery {
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

        func matches(_ item: RegionalSlotReview) -> Bool {
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

        func apply(_ items: [RegionalSlotReview]) -> [RegionalSlotReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalSlotReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalSlotReviews(_ store: any RegionalSlotReviewStore, query: RegionalSlotReviewQuery) -> [RegionalSlotReview] {
        return query.apply(store.list())
    }
}
