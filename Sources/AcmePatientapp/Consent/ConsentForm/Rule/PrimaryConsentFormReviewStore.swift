import AcmePlatform
import Foundation

extension Consent {
    /// Keeps primary consent form reviews by code.
    protocol PrimaryConsentFormReviewStore {
        func find(_ code: String) -> PrimaryConsentFormReview?
        func save(_ item: PrimaryConsentFormReview)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryConsentFormReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryConsentFormReviewStore: PrimaryConsentFormReviewStore {
        var items: [String: PrimaryConsentFormReview]
        var order: [String]

        init(items: [String: PrimaryConsentFormReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryConsentFormReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryConsentFormReview) {
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

        func list() -> [PrimaryConsentFormReview] {
            var out: [PrimaryConsentFormReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryConsentFormReviewStore() -> any PrimaryConsentFormReviewStore {
        return MemoryPrimaryConsentFormReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryConsentFormReviewStore: PrimaryConsentFormReviewStore {
        var inner: MemoryPrimaryConsentFormReviewStore
        var cache: TTLCache<PrimaryConsentFormReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryConsentFormReviewStore, cache: TTLCache<PrimaryConsentFormReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryConsentFormReview? {
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

        func save(_ item: PrimaryConsentFormReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryConsentFormReview] {
            return inner.list()
        }
    }

    static func newCachedPrimaryConsentFormReviewStore(_ inner: MemoryPrimaryConsentFormReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryConsentFormReviewStore {
        return CachedPrimaryConsentFormReviewStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary consent form reviews. Empty fields match all.
    final class PrimaryConsentFormReviewQuery {
        var title: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryConsentFormReview) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryConsentFormReview]) -> [PrimaryConsentFormReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryConsentFormReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryConsentFormReviews(_ store: any PrimaryConsentFormReviewStore, query: PrimaryConsentFormReviewQuery) -> [PrimaryConsentFormReview] {
        return query.apply(store.list())
    }
}
