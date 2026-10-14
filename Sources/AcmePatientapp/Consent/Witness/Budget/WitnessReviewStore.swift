import AcmePlatform
import Foundation

extension Consent {
    /// Keeps witness reviews by code.
    protocol WitnessReviewStore {
        func find(_ code: String) -> WitnessReview?
        func save(_ item: WitnessReview)
        func remove(_ code: String) -> Bool
        func list() -> [WitnessReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWitnessReviewStore: WitnessReviewStore {
        var items: [String: WitnessReview]
        var order: [String]

        init(items: [String: WitnessReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WitnessReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WitnessReview) {
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

        func list() -> [WitnessReview] {
            var out: [WitnessReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWitnessReviewStore() -> any WitnessReviewStore {
        return MemoryWitnessReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWitnessReviewStore: WitnessReviewStore {
        var inner: MemoryWitnessReviewStore
        var cache: TTLCache<WitnessReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryWitnessReviewStore, cache: TTLCache<WitnessReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WitnessReview? {
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

        func save(_ item: WitnessReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WitnessReview] {
            return inner.list()
        }
    }

    static func newCachedWitnessReviewStore(_ inner: MemoryWitnessReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WitnessReviewStore {
        return CachedWitnessReviewStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects witness reviews. Empty fields match all.
    final class WitnessReviewQuery {
        var name: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WitnessReview) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [WitnessReview]) -> [WitnessReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WitnessReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWitnessReviews(_ store: any WitnessReviewStore, query: WitnessReviewQuery) -> [WitnessReview] {
        return query.apply(store.list())
    }
}
