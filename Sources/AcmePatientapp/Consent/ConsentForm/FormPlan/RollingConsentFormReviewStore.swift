import AcmePlatform
import Foundation

extension Consent {
    /// Keeps rolling consent form reviews by code.
    protocol RollingConsentFormReviewStore {
        func find(_ code: String) -> RollingConsentFormReview?
        func save(_ item: RollingConsentFormReview)
        func remove(_ code: String) -> Bool
        func list() -> [RollingConsentFormReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingConsentFormReviewStore: RollingConsentFormReviewStore {
        var items: [String: RollingConsentFormReview]
        var order: [String]

        init(items: [String: RollingConsentFormReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingConsentFormReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingConsentFormReview) {
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

        func list() -> [RollingConsentFormReview] {
            var out: [RollingConsentFormReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingConsentFormReviewStore() -> any RollingConsentFormReviewStore {
        return MemoryRollingConsentFormReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingConsentFormReviewStore: RollingConsentFormReviewStore {
        var inner: MemoryRollingConsentFormReviewStore
        var cache: TTLCache<RollingConsentFormReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingConsentFormReviewStore, cache: TTLCache<RollingConsentFormReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingConsentFormReview? {
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

        func save(_ item: RollingConsentFormReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingConsentFormReview] {
            return inner.list()
        }
    }

    static func newCachedRollingConsentFormReviewStore(_ inner: MemoryRollingConsentFormReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingConsentFormReviewStore {
        return CachedRollingConsentFormReviewStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling consent form reviews. Empty fields match all.
    final class RollingConsentFormReviewQuery {
        var category: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minPriority: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingConsentFormReview) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingConsentFormReview]) -> [RollingConsentFormReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingConsentFormReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingConsentFormReviews(_ store: any RollingConsentFormReviewStore, query: RollingConsentFormReviewQuery) -> [RollingConsentFormReview] {
        return query.apply(store.list())
    }
}
