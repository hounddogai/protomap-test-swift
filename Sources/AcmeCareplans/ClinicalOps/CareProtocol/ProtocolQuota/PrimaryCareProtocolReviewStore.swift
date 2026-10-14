import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps primary care protocol reviews by code.
    protocol PrimaryCareProtocolReviewStore {
        func find(_ code: String) -> PrimaryCareProtocolReview?
        func save(_ item: PrimaryCareProtocolReview)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryCareProtocolReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryCareProtocolReviewStore: PrimaryCareProtocolReviewStore {
        var items: [String: PrimaryCareProtocolReview]
        var order: [String]

        init(items: [String: PrimaryCareProtocolReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryCareProtocolReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryCareProtocolReview) {
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

        func list() -> [PrimaryCareProtocolReview] {
            var out: [PrimaryCareProtocolReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryCareProtocolReviewStore() -> any PrimaryCareProtocolReviewStore {
        return MemoryPrimaryCareProtocolReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryCareProtocolReviewStore: PrimaryCareProtocolReviewStore {
        var inner: MemoryPrimaryCareProtocolReviewStore
        var cache: TTLCache<PrimaryCareProtocolReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryCareProtocolReviewStore, cache: TTLCache<PrimaryCareProtocolReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryCareProtocolReview? {
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

        func save(_ item: PrimaryCareProtocolReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryCareProtocolReview] {
            return inner.list()
        }
    }

    static func newCachedPrimaryCareProtocolReviewStore(_ inner: MemoryPrimaryCareProtocolReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryCareProtocolReviewStore {
        return CachedPrimaryCareProtocolReviewStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary care protocol reviews. Empty fields match all.
    final class PrimaryCareProtocolReviewQuery {
        var title: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryCareProtocolReview) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [PrimaryCareProtocolReview]) -> [PrimaryCareProtocolReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryCareProtocolReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryCareProtocolReviews(_ store: any PrimaryCareProtocolReviewStore, query: PrimaryCareProtocolReviewQuery) -> [PrimaryCareProtocolReview] {
        return query.apply(store.list())
    }
}
