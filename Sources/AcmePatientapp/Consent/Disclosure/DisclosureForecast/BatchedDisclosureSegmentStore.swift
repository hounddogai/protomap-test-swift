import AcmePlatform
import Foundation

extension Consent {
    /// Keeps batched disclosure segments by code.
    protocol BatchedDisclosureSegmentStore {
        func find(_ code: String) -> BatchedDisclosureSegment?
        func save(_ item: BatchedDisclosureSegment)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedDisclosureSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedDisclosureSegmentStore: BatchedDisclosureSegmentStore {
        var items: [String: BatchedDisclosureSegment]
        var order: [String]

        init(items: [String: BatchedDisclosureSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedDisclosureSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedDisclosureSegment) {
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

        func list() -> [BatchedDisclosureSegment] {
            var out: [BatchedDisclosureSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedDisclosureSegmentStore() -> any BatchedDisclosureSegmentStore {
        return MemoryBatchedDisclosureSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedDisclosureSegmentStore: BatchedDisclosureSegmentStore {
        var inner: MemoryBatchedDisclosureSegmentStore
        var cache: TTLCache<BatchedDisclosureSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedDisclosureSegmentStore, cache: TTLCache<BatchedDisclosureSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedDisclosureSegment? {
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

        func save(_ item: BatchedDisclosureSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedDisclosureSegment] {
            return inner.list()
        }
    }

    static func newCachedBatchedDisclosureSegmentStore(_ inner: MemoryBatchedDisclosureSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedDisclosureSegmentStore {
        return CachedBatchedDisclosureSegmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched disclosure segments. Empty fields match all.
    final class BatchedDisclosureSegmentQuery {
        var category: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minCost: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedDisclosureSegment) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedDisclosureSegment]) -> [BatchedDisclosureSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedDisclosureSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedDisclosureSegments(_ store: any BatchedDisclosureSegmentStore, query: BatchedDisclosureSegmentQuery) -> [BatchedDisclosureSegment] {
        return query.apply(store.list())
    }
}
