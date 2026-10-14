import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps batched outreach cycles by code.
    protocol BatchedOutreachCycleStore {
        func find(_ code: String) -> BatchedOutreachCycle?
        func save(_ item: BatchedOutreachCycle)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedOutreachCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedOutreachCycleStore: BatchedOutreachCycleStore {
        var items: [String: BatchedOutreachCycle]
        var order: [String]

        init(items: [String: BatchedOutreachCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedOutreachCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedOutreachCycle) {
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

        func list() -> [BatchedOutreachCycle] {
            var out: [BatchedOutreachCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedOutreachCycleStore() -> any BatchedOutreachCycleStore {
        return MemoryBatchedOutreachCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedOutreachCycleStore: BatchedOutreachCycleStore {
        var inner: MemoryBatchedOutreachCycleStore
        var cache: TTLCache<BatchedOutreachCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedOutreachCycleStore, cache: TTLCache<BatchedOutreachCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedOutreachCycle? {
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

        func save(_ item: BatchedOutreachCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedOutreachCycle] {
            return inner.list()
        }
    }

    static func newCachedBatchedOutreachCycleStore(_ inner: MemoryBatchedOutreachCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedOutreachCycleStore {
        return CachedBatchedOutreachCycleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched outreach cycles. Empty fields match all.
    final class BatchedOutreachCycleQuery {
        var title: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedOutreachCycle) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedOutreachCycle]) -> [BatchedOutreachCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedOutreachCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedOutreachCycles(_ store: any BatchedOutreachCycleStore, query: BatchedOutreachCycleQuery) -> [BatchedOutreachCycle] {
        return query.apply(store.list())
    }
}
