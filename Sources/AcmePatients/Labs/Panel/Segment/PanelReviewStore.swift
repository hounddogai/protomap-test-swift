import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel reviews by code.
    protocol PanelReviewStore {
        func find(_ code: String) -> PanelReview?
        func save(_ item: PanelReview)
        func remove(_ code: String) -> Bool
        func list() -> [PanelReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelReviewStore: PanelReviewStore {
        var items: [String: PanelReview]
        var order: [String]

        init(items: [String: PanelReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelReview) {
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

        func list() -> [PanelReview] {
            var out: [PanelReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelReviewStore() -> any PanelReviewStore {
        return MemoryPanelReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelReviewStore: PanelReviewStore {
        var inner: MemoryPanelReviewStore
        var cache: TTLCache<PanelReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelReviewStore, cache: TTLCache<PanelReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelReview? {
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

        func save(_ item: PanelReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelReview] {
            return inner.list()
        }
    }

    static func newCachedPanelReviewStore(_ inner: MemoryPanelReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelReviewStore {
        return CachedPanelReviewStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel reviews. Empty fields match all.
    final class PanelReviewQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelReview) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PanelReview]) -> [PanelReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelReviews(_ store: any PanelReviewStore, query: PanelReviewQuery) -> [PanelReview] {
        return query.apply(store.list())
    }
}
