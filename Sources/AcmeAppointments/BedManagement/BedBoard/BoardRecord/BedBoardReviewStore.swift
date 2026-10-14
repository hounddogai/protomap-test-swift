import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board reviews by code.
    protocol BedBoardReviewStore {
        func find(_ code: String) -> BedBoardReview?
        func save(_ item: BedBoardReview)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardReviewStore: BedBoardReviewStore {
        var items: [String: BedBoardReview]
        var order: [String]

        init(items: [String: BedBoardReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardReview) {
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

        func list() -> [BedBoardReview] {
            var out: [BedBoardReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardReviewStore() -> any BedBoardReviewStore {
        return MemoryBedBoardReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardReviewStore: BedBoardReviewStore {
        var inner: MemoryBedBoardReviewStore
        var cache: TTLCache<BedBoardReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardReviewStore, cache: TTLCache<BedBoardReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardReview? {
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

        func save(_ item: BedBoardReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardReview] {
            return inner.list()
        }
    }

    static func newCachedBedBoardReviewStore(_ inner: MemoryBedBoardReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardReviewStore {
        return CachedBedBoardReviewStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board reviews. Empty fields match all.
    final class BedBoardReviewQuery {
        var name: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minAmount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardReview) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BedBoardReview]) -> [BedBoardReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardReviews(_ store: any BedBoardReviewStore, query: BedBoardReviewQuery) -> [BedBoardReview] {
        return query.apply(store.list())
    }
}
