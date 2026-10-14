import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps pending bed board reviews by code.
    protocol PendingBedBoardReviewStore {
        func find(_ code: String) -> PendingBedBoardReview?
        func save(_ item: PendingBedBoardReview)
        func remove(_ code: String) -> Bool
        func list() -> [PendingBedBoardReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingBedBoardReviewStore: PendingBedBoardReviewStore {
        var items: [String: PendingBedBoardReview]
        var order: [String]

        init(items: [String: PendingBedBoardReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingBedBoardReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingBedBoardReview) {
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

        func list() -> [PendingBedBoardReview] {
            var out: [PendingBedBoardReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingBedBoardReviewStore() -> any PendingBedBoardReviewStore {
        return MemoryPendingBedBoardReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingBedBoardReviewStore: PendingBedBoardReviewStore {
        var inner: MemoryPendingBedBoardReviewStore
        var cache: TTLCache<PendingBedBoardReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingBedBoardReviewStore, cache: TTLCache<PendingBedBoardReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingBedBoardReview? {
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

        func save(_ item: PendingBedBoardReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingBedBoardReview] {
            return inner.list()
        }
    }

    static func newCachedPendingBedBoardReviewStore(_ inner: MemoryPendingBedBoardReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingBedBoardReviewStore {
        return CachedPendingBedBoardReviewStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending bed board reviews. Empty fields match all.
    final class PendingBedBoardReviewQuery {
        var source: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minRevision: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingBedBoardReview) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingBedBoardReview]) -> [PendingBedBoardReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingBedBoardReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingBedBoardReviews(_ store: any PendingBedBoardReviewStore, query: PendingBedBoardReviewQuery) -> [PendingBedBoardReview] {
        return query.apply(store.list())
    }
}
