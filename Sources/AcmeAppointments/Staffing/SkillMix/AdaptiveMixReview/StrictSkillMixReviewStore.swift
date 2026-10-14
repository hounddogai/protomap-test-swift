import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps strict skill mix reviews by code.
    protocol StrictSkillMixReviewStore {
        func find(_ code: String) -> StrictSkillMixReview?
        func save(_ item: StrictSkillMixReview)
        func remove(_ code: String) -> Bool
        func list() -> [StrictSkillMixReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictSkillMixReviewStore: StrictSkillMixReviewStore {
        var items: [String: StrictSkillMixReview]
        var order: [String]

        init(items: [String: StrictSkillMixReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictSkillMixReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictSkillMixReview) {
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

        func list() -> [StrictSkillMixReview] {
            var out: [StrictSkillMixReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictSkillMixReviewStore() -> any StrictSkillMixReviewStore {
        return MemoryStrictSkillMixReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictSkillMixReviewStore: StrictSkillMixReviewStore {
        var inner: MemoryStrictSkillMixReviewStore
        var cache: TTLCache<StrictSkillMixReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictSkillMixReviewStore, cache: TTLCache<StrictSkillMixReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictSkillMixReview? {
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

        func save(_ item: StrictSkillMixReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictSkillMixReview] {
            return inner.list()
        }
    }

    static func newCachedStrictSkillMixReviewStore(_ inner: MemoryStrictSkillMixReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictSkillMixReviewStore {
        return CachedStrictSkillMixReviewStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict skill mix reviews. Empty fields match all.
    final class StrictSkillMixReviewQuery {
        var segment: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictSkillMixReview) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictSkillMixReview]) -> [StrictSkillMixReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictSkillMixReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictSkillMixReviews(_ store: any StrictSkillMixReviewStore, query: StrictSkillMixReviewQuery) -> [StrictSkillMixReview] {
        return query.apply(store.list())
    }
}
