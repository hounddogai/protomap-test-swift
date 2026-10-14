import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps primary credential reviews by code.
    protocol PrimaryCredentialReviewStore {
        func find(_ code: String) -> PrimaryCredentialReview?
        func save(_ item: PrimaryCredentialReview)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryCredentialReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryCredentialReviewStore: PrimaryCredentialReviewStore {
        var items: [String: PrimaryCredentialReview]
        var order: [String]

        init(items: [String: PrimaryCredentialReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryCredentialReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryCredentialReview) {
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

        func list() -> [PrimaryCredentialReview] {
            var out: [PrimaryCredentialReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryCredentialReviewStore() -> any PrimaryCredentialReviewStore {
        return MemoryPrimaryCredentialReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryCredentialReviewStore: PrimaryCredentialReviewStore {
        var inner: MemoryPrimaryCredentialReviewStore
        var cache: TTLCache<PrimaryCredentialReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryCredentialReviewStore, cache: TTLCache<PrimaryCredentialReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryCredentialReview? {
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

        func save(_ item: PrimaryCredentialReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryCredentialReview] {
            return inner.list()
        }
    }

    static func newCachedPrimaryCredentialReviewStore(_ inner: MemoryPrimaryCredentialReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryCredentialReviewStore {
        return CachedPrimaryCredentialReviewStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary credential reviews. Empty fields match all.
    final class PrimaryCredentialReviewQuery {
        var region: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryCredentialReview) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryCredentialReview]) -> [PrimaryCredentialReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryCredentialReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryCredentialReviews(_ store: any PrimaryCredentialReviewStore, query: PrimaryCredentialReviewQuery) -> [PrimaryCredentialReview] {
        return query.apply(store.list())
    }
}
