import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps legacy bed board reviews by code.
    protocol LegacyBedBoardReviewStore {
        func find(_ code: String) -> LegacyBedBoardReview?
        func save(_ item: LegacyBedBoardReview)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyBedBoardReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyBedBoardReviewStore: LegacyBedBoardReviewStore {
        var items: [String: LegacyBedBoardReview]
        var order: [String]

        init(items: [String: LegacyBedBoardReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyBedBoardReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyBedBoardReview) {
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

        func list() -> [LegacyBedBoardReview] {
            var out: [LegacyBedBoardReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyBedBoardReviewStore() -> any LegacyBedBoardReviewStore {
        return MemoryLegacyBedBoardReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyBedBoardReviewStore: LegacyBedBoardReviewStore {
        var inner: MemoryLegacyBedBoardReviewStore
        var cache: TTLCache<LegacyBedBoardReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyBedBoardReviewStore, cache: TTLCache<LegacyBedBoardReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyBedBoardReview? {
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

        func save(_ item: LegacyBedBoardReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyBedBoardReview] {
            return inner.list()
        }
    }

    static func newCachedLegacyBedBoardReviewStore(_ inner: MemoryLegacyBedBoardReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyBedBoardReviewStore {
        return CachedLegacyBedBoardReviewStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy bed board reviews. Empty fields match all.
    final class LegacyBedBoardReviewQuery {
        var segment: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyBedBoardReview) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyBedBoardReview]) -> [LegacyBedBoardReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyBedBoardReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyBedBoardReviews(_ store: any LegacyBedBoardReviewStore, query: LegacyBedBoardReviewQuery) -> [LegacyBedBoardReview] {
        return query.apply(store.list())
    }
}
