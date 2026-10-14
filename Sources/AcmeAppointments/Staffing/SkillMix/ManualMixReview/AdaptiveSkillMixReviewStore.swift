import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps adaptive skill mix reviews by code.
    protocol AdaptiveSkillMixReviewStore {
        func find(_ code: String) -> AdaptiveSkillMixReview?
        func save(_ item: AdaptiveSkillMixReview)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveSkillMixReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveSkillMixReviewStore: AdaptiveSkillMixReviewStore {
        var items: [String: AdaptiveSkillMixReview]
        var order: [String]

        init(items: [String: AdaptiveSkillMixReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveSkillMixReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveSkillMixReview) {
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

        func list() -> [AdaptiveSkillMixReview] {
            var out: [AdaptiveSkillMixReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveSkillMixReviewStore() -> any AdaptiveSkillMixReviewStore {
        return MemoryAdaptiveSkillMixReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveSkillMixReviewStore: AdaptiveSkillMixReviewStore {
        var inner: MemoryAdaptiveSkillMixReviewStore
        var cache: TTLCache<AdaptiveSkillMixReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveSkillMixReviewStore, cache: TTLCache<AdaptiveSkillMixReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveSkillMixReview? {
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

        func save(_ item: AdaptiveSkillMixReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveSkillMixReview] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveSkillMixReviewStore(_ inner: MemoryAdaptiveSkillMixReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveSkillMixReviewStore {
        return CachedAdaptiveSkillMixReviewStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive skill mix reviews. Empty fields match all.
    final class AdaptiveSkillMixReviewQuery {
        var label: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minAmount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveSkillMixReview) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [AdaptiveSkillMixReview]) -> [AdaptiveSkillMixReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveSkillMixReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveSkillMixReviews(_ store: any AdaptiveSkillMixReviewStore, query: AdaptiveSkillMixReviewQuery) -> [AdaptiveSkillMixReview] {
        return query.apply(store.list())
    }
}
