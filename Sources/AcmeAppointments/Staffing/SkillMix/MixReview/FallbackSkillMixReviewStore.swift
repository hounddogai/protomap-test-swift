import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps fallback skill mix reviews by code.
    protocol FallbackSkillMixReviewStore {
        func find(_ code: String) -> FallbackSkillMixReview?
        func save(_ item: FallbackSkillMixReview)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackSkillMixReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackSkillMixReviewStore: FallbackSkillMixReviewStore {
        var items: [String: FallbackSkillMixReview]
        var order: [String]

        init(items: [String: FallbackSkillMixReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackSkillMixReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackSkillMixReview) {
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

        func list() -> [FallbackSkillMixReview] {
            var out: [FallbackSkillMixReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackSkillMixReviewStore() -> any FallbackSkillMixReviewStore {
        return MemoryFallbackSkillMixReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackSkillMixReviewStore: FallbackSkillMixReviewStore {
        var inner: MemoryFallbackSkillMixReviewStore
        var cache: TTLCache<FallbackSkillMixReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackSkillMixReviewStore, cache: TTLCache<FallbackSkillMixReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackSkillMixReview? {
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

        func save(_ item: FallbackSkillMixReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackSkillMixReview] {
            return inner.list()
        }
    }

    static func newCachedFallbackSkillMixReviewStore(_ inner: MemoryFallbackSkillMixReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackSkillMixReviewStore {
        return CachedFallbackSkillMixReviewStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback skill mix reviews. Empty fields match all.
    final class FallbackSkillMixReviewQuery {
        var name: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRefills: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackSkillMixReview) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [FallbackSkillMixReview]) -> [FallbackSkillMixReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackSkillMixReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackSkillMixReviews(_ store: any FallbackSkillMixReviewStore, query: FallbackSkillMixReviewQuery) -> [FallbackSkillMixReview] {
        return query.apply(store.list())
    }
}
