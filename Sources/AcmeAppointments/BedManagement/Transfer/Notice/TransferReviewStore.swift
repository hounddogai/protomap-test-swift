import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer reviews by code.
    protocol TransferReviewStore {
        func find(_ code: String) -> TransferReview?
        func save(_ item: TransferReview)
        func remove(_ code: String) -> Bool
        func list() -> [TransferReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferReviewStore: TransferReviewStore {
        var items: [String: TransferReview]
        var order: [String]

        init(items: [String: TransferReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferReview) {
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

        func list() -> [TransferReview] {
            var out: [TransferReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferReviewStore() -> any TransferReviewStore {
        return MemoryTransferReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferReviewStore: TransferReviewStore {
        var inner: MemoryTransferReviewStore
        var cache: TTLCache<TransferReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferReviewStore, cache: TTLCache<TransferReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferReview? {
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

        func save(_ item: TransferReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferReview] {
            return inner.list()
        }
    }

    static func newCachedTransferReviewStore(_ inner: MemoryTransferReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferReviewStore {
        return CachedTransferReviewStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer reviews. Empty fields match all.
    final class TransferReviewQuery {
        var name: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minLimit: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferReview) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TransferReview]) -> [TransferReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferReviews(_ store: any TransferReviewStore, query: TransferReviewQuery) -> [TransferReview] {
        return query.apply(store.list())
    }
}
