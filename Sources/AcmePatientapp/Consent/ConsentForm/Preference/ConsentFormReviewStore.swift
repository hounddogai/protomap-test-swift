import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form reviews by code.
    protocol ConsentFormReviewStore {
        func find(_ code: String) -> ConsentFormReview?
        func save(_ item: ConsentFormReview)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormReviewStore: ConsentFormReviewStore {
        var items: [String: ConsentFormReview]
        var order: [String]

        init(items: [String: ConsentFormReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormReview) {
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

        func list() -> [ConsentFormReview] {
            var out: [ConsentFormReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormReviewStore() -> any ConsentFormReviewStore {
        return MemoryConsentFormReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormReviewStore: ConsentFormReviewStore {
        var inner: MemoryConsentFormReviewStore
        var cache: TTLCache<ConsentFormReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormReviewStore, cache: TTLCache<ConsentFormReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormReview? {
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

        func save(_ item: ConsentFormReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormReview] {
            return inner.list()
        }
    }

    static func newCachedConsentFormReviewStore(_ inner: MemoryConsentFormReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormReviewStore {
        return CachedConsentFormReviewStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form reviews. Empty fields match all.
    final class ConsentFormReviewQuery {
        var unit: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minPriority: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ConsentFormReview) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [ConsentFormReview]) -> [ConsentFormReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormReviews(_ store: any ConsentFormReviewStore, query: ConsentFormReviewQuery) -> [ConsentFormReview] {
        return query.apply(store.list())
    }
}
