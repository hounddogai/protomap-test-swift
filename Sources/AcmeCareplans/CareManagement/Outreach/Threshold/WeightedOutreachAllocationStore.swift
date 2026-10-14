import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps weighted outreach allocations by code.
    protocol WeightedOutreachAllocationStore {
        func find(_ code: String) -> WeightedOutreachAllocation?
        func save(_ item: WeightedOutreachAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedOutreachAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedOutreachAllocationStore: WeightedOutreachAllocationStore {
        var items: [String: WeightedOutreachAllocation]
        var order: [String]

        init(items: [String: WeightedOutreachAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedOutreachAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedOutreachAllocation) {
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

        func list() -> [WeightedOutreachAllocation] {
            var out: [WeightedOutreachAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedOutreachAllocationStore() -> any WeightedOutreachAllocationStore {
        return MemoryWeightedOutreachAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedOutreachAllocationStore: WeightedOutreachAllocationStore {
        var inner: MemoryWeightedOutreachAllocationStore
        var cache: TTLCache<WeightedOutreachAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedOutreachAllocationStore, cache: TTLCache<WeightedOutreachAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedOutreachAllocation? {
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

        func save(_ item: WeightedOutreachAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedOutreachAllocation] {
            return inner.list()
        }
    }

    static func newCachedWeightedOutreachAllocationStore(_ inner: MemoryWeightedOutreachAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedOutreachAllocationStore {
        return CachedWeightedOutreachAllocationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted outreach allocations. Empty fields match all.
    final class WeightedOutreachAllocationQuery {
        var segment: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedOutreachAllocation) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedOutreachAllocation]) -> [WeightedOutreachAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedOutreachAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedOutreachAllocations(_ store: any WeightedOutreachAllocationStore, query: WeightedOutreachAllocationQuery) -> [WeightedOutreachAllocation] {
        return query.apply(store.list())
    }
}
