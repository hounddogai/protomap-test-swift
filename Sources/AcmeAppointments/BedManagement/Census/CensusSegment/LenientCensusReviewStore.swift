import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps lenient census reviews by code.
    protocol LenientCensusReviewStore {
        func find(_ code: String) -> LenientCensusReview?
        func save(_ item: LenientCensusReview)
        func remove(_ code: String) -> Bool
        func list() -> [LenientCensusReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientCensusReviewStore: LenientCensusReviewStore {
        var items: [String: LenientCensusReview]
        var order: [String]

        init(items: [String: LenientCensusReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientCensusReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientCensusReview) {
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

        func list() -> [LenientCensusReview] {
            var out: [LenientCensusReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientCensusReviewStore() -> any LenientCensusReviewStore {
        return MemoryLenientCensusReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientCensusReviewStore: LenientCensusReviewStore {
        var inner: MemoryLenientCensusReviewStore
        var cache: TTLCache<LenientCensusReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientCensusReviewStore, cache: TTLCache<LenientCensusReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientCensusReview? {
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

        func save(_ item: LenientCensusReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientCensusReview] {
            return inner.list()
        }
    }

    static func newCachedLenientCensusReviewStore(_ inner: MemoryLenientCensusReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientCensusReviewStore {
        return CachedLenientCensusReviewStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient census reviews. Empty fields match all.
    final class LenientCensusReviewQuery {
        var country: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientCensusReview) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientCensusReview]) -> [LenientCensusReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientCensusReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientCensusReviews(_ store: any LenientCensusReviewStore, query: LenientCensusReviewQuery) -> [LenientCensusReview] {
        return query.apply(store.list())
    }
}
