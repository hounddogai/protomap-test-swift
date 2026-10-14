import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps pending census reviews by code.
    protocol PendingCensusReviewStore {
        func find(_ code: String) -> PendingCensusReview?
        func save(_ item: PendingCensusReview)
        func remove(_ code: String) -> Bool
        func list() -> [PendingCensusReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingCensusReviewStore: PendingCensusReviewStore {
        var items: [String: PendingCensusReview]
        var order: [String]

        init(items: [String: PendingCensusReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingCensusReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingCensusReview) {
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

        func list() -> [PendingCensusReview] {
            var out: [PendingCensusReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingCensusReviewStore() -> any PendingCensusReviewStore {
        return MemoryPendingCensusReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingCensusReviewStore: PendingCensusReviewStore {
        var inner: MemoryPendingCensusReviewStore
        var cache: TTLCache<PendingCensusReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingCensusReviewStore, cache: TTLCache<PendingCensusReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingCensusReview? {
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

        func save(_ item: PendingCensusReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingCensusReview] {
            return inner.list()
        }
    }

    static func newCachedPendingCensusReviewStore(_ inner: MemoryPendingCensusReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingCensusReviewStore {
        return CachedPendingCensusReviewStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending census reviews. Empty fields match all.
    final class PendingCensusReviewQuery {
        var unit: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minRefills: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingCensusReview) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingCensusReview]) -> [PendingCensusReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingCensusReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingCensusReviews(_ store: any PendingCensusReviewStore, query: PendingCensusReviewQuery) -> [PendingCensusReview] {
        return query.apply(store.list())
    }
}
