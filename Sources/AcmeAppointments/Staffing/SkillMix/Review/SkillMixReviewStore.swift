import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix reviews by code.
    protocol SkillMixReviewStore {
        func find(_ code: String) -> SkillMixReview?
        func save(_ item: SkillMixReview)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixReviewStore: SkillMixReviewStore {
        var items: [String: SkillMixReview]
        var order: [String]

        init(items: [String: SkillMixReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixReview) {
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

        func list() -> [SkillMixReview] {
            var out: [SkillMixReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixReviewStore() -> any SkillMixReviewStore {
        return MemorySkillMixReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixReviewStore: SkillMixReviewStore {
        var inner: MemorySkillMixReviewStore
        var cache: TTLCache<SkillMixReview>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixReviewStore, cache: TTLCache<SkillMixReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixReview? {
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

        func save(_ item: SkillMixReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixReview] {
            return inner.list()
        }
    }

    static func newCachedSkillMixReviewStore(_ inner: MemorySkillMixReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixReviewStore {
        return CachedSkillMixReviewStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix reviews. Empty fields match all.
    final class SkillMixReviewQuery {
        var name: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixReview) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixReview]) -> [SkillMixReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixReviews(_ store: any SkillMixReviewStore, query: SkillMixReviewQuery) -> [SkillMixReview] {
        return query.apply(store.list())
    }
}
