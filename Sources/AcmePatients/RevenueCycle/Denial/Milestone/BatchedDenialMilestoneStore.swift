import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps batched denial milestones by code.
    protocol BatchedDenialMilestoneStore {
        func find(_ code: String) -> BatchedDenialMilestone?
        func save(_ item: BatchedDenialMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedDenialMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedDenialMilestoneStore: BatchedDenialMilestoneStore {
        var items: [String: BatchedDenialMilestone]
        var order: [String]

        init(items: [String: BatchedDenialMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedDenialMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedDenialMilestone) {
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

        func list() -> [BatchedDenialMilestone] {
            var out: [BatchedDenialMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedDenialMilestoneStore() -> any BatchedDenialMilestoneStore {
        return MemoryBatchedDenialMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedDenialMilestoneStore: BatchedDenialMilestoneStore {
        var inner: MemoryBatchedDenialMilestoneStore
        var cache: TTLCache<BatchedDenialMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedDenialMilestoneStore, cache: TTLCache<BatchedDenialMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedDenialMilestone? {
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

        func save(_ item: BatchedDenialMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedDenialMilestone] {
            return inner.list()
        }
    }

    static func newCachedBatchedDenialMilestoneStore(_ inner: MemoryBatchedDenialMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedDenialMilestoneStore {
        return CachedBatchedDenialMilestoneStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched denial milestones. Empty fields match all.
    final class BatchedDenialMilestoneQuery {
        var locale: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedDenialMilestone) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedDenialMilestone]) -> [BatchedDenialMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedDenialMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedDenialMilestones(_ store: any BatchedDenialMilestoneStore, query: BatchedDenialMilestoneQuery) -> [BatchedDenialMilestone] {
        return query.apply(store.list())
    }
}
