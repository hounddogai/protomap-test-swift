import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps legacy modality reviews by code.
    protocol LegacyModalityReviewStore {
        func find(_ code: String) -> LegacyModalityReview?
        func save(_ item: LegacyModalityReview)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyModalityReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyModalityReviewStore: LegacyModalityReviewStore {
        var items: [String: LegacyModalityReview]
        var order: [String]

        init(items: [String: LegacyModalityReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyModalityReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyModalityReview) {
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

        func list() -> [LegacyModalityReview] {
            var out: [LegacyModalityReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyModalityReviewStore() -> any LegacyModalityReviewStore {
        return MemoryLegacyModalityReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyModalityReviewStore: LegacyModalityReviewStore {
        var inner: MemoryLegacyModalityReviewStore
        var cache: TTLCache<LegacyModalityReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyModalityReviewStore, cache: TTLCache<LegacyModalityReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyModalityReview? {
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

        func save(_ item: LegacyModalityReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyModalityReview] {
            return inner.list()
        }
    }

    static func newCachedLegacyModalityReviewStore(_ inner: MemoryLegacyModalityReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyModalityReviewStore {
        return CachedLegacyModalityReviewStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy modality reviews. Empty fields match all.
    final class LegacyModalityReviewQuery {
        var unit: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyModalityReview) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [LegacyModalityReview]) -> [LegacyModalityReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyModalityReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyModalityReviews(_ store: any LegacyModalityReviewStore, query: LegacyModalityReviewQuery) -> [LegacyModalityReview] {
        return query.apply(store.list())
    }
}
