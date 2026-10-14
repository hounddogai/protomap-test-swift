import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure reviews by code.
    protocol DisclosureReviewStore {
        func find(_ code: String) -> DisclosureReview?
        func save(_ item: DisclosureReview)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureReviewStore: DisclosureReviewStore {
        var items: [String: DisclosureReview]
        var order: [String]

        init(items: [String: DisclosureReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureReview) {
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

        func list() -> [DisclosureReview] {
            var out: [DisclosureReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureReviewStore() -> any DisclosureReviewStore {
        return MemoryDisclosureReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureReviewStore: DisclosureReviewStore {
        var inner: MemoryDisclosureReviewStore
        var cache: TTLCache<DisclosureReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureReviewStore, cache: TTLCache<DisclosureReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureReview? {
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

        func save(_ item: DisclosureReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureReview] {
            return inner.list()
        }
    }

    static func newCachedDisclosureReviewStore(_ inner: MemoryDisclosureReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureReviewStore {
        return CachedDisclosureReviewStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure reviews. Empty fields match all.
    final class DisclosureReviewQuery {
        var label: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRetries: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureReview) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DisclosureReview]) -> [DisclosureReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureReviews(_ store: any DisclosureReviewStore, query: DisclosureReviewQuery) -> [DisclosureReview] {
        return query.apply(store.list())
    }
}
