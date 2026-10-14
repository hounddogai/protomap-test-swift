import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality reviews by code.
    protocol ModalityReviewStore {
        func find(_ code: String) -> ModalityReview?
        func save(_ item: ModalityReview)
        func remove(_ code: String) -> Bool
        func list() -> [ModalityReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalityReviewStore: ModalityReviewStore {
        var items: [String: ModalityReview]
        var order: [String]

        init(items: [String: ModalityReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalityReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalityReview) {
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

        func list() -> [ModalityReview] {
            var out: [ModalityReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalityReviewStore() -> any ModalityReviewStore {
        return MemoryModalityReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalityReviewStore: ModalityReviewStore {
        var inner: MemoryModalityReviewStore
        var cache: TTLCache<ModalityReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalityReviewStore, cache: TTLCache<ModalityReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalityReview? {
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

        func save(_ item: ModalityReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalityReview] {
            return inner.list()
        }
    }

    static func newCachedModalityReviewStore(_ inner: MemoryModalityReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalityReviewStore {
        return CachedModalityReviewStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality reviews. Empty fields match all.
    final class ModalityReviewQuery {
        var channel: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minSequence: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ModalityReview) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ModalityReview]) -> [ModalityReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalityReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalityReviews(_ store: any ModalityReviewStore, query: ModalityReviewQuery) -> [ModalityReview] {
        return query.apply(store.list())
    }
}
