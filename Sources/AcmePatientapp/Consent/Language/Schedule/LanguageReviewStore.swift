import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language reviews by code.
    protocol LanguageReviewStore {
        func find(_ code: String) -> LanguageReview?
        func save(_ item: LanguageReview)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageReviewStore: LanguageReviewStore {
        var items: [String: LanguageReview]
        var order: [String]

        init(items: [String: LanguageReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageReview) {
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

        func list() -> [LanguageReview] {
            var out: [LanguageReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageReviewStore() -> any LanguageReviewStore {
        return MemoryLanguageReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageReviewStore: LanguageReviewStore {
        var inner: MemoryLanguageReviewStore
        var cache: TTLCache<LanguageReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageReviewStore, cache: TTLCache<LanguageReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageReview? {
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

        func save(_ item: LanguageReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageReview] {
            return inner.list()
        }
    }

    static func newCachedLanguageReviewStore(_ inner: MemoryLanguageReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageReviewStore {
        return CachedLanguageReviewStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language reviews. Empty fields match all.
    final class LanguageReviewQuery {
        var region: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageReview) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LanguageReview]) -> [LanguageReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageReviews(_ store: any LanguageReviewStore, query: LanguageReviewQuery) -> [LanguageReview] {
        return query.apply(store.list())
    }
}
