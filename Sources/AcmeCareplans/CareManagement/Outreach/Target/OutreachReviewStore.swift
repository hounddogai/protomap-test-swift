import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach reviews by code.
    protocol OutreachReviewStore {
        func find(_ code: String) -> OutreachReview?
        func save(_ item: OutreachReview)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachReviewStore: OutreachReviewStore {
        var items: [String: OutreachReview]
        var order: [String]

        init(items: [String: OutreachReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachReview) {
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

        func list() -> [OutreachReview] {
            var out: [OutreachReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachReviewStore() -> any OutreachReviewStore {
        return MemoryOutreachReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachReviewStore: OutreachReviewStore {
        var inner: MemoryOutreachReviewStore
        var cache: TTLCache<OutreachReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachReviewStore, cache: TTLCache<OutreachReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachReview? {
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

        func save(_ item: OutreachReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachReview] {
            return inner.list()
        }
    }

    static func newCachedOutreachReviewStore(_ inner: MemoryOutreachReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachReviewStore {
        return CachedOutreachReviewStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach reviews. Empty fields match all.
    final class OutreachReviewQuery {
        var category: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minRefills: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachReview) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [OutreachReview]) -> [OutreachReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachReviews(_ store: any OutreachReviewStore, query: OutreachReviewQuery) -> [OutreachReview] {
        return query.apply(store.list())
    }
}
