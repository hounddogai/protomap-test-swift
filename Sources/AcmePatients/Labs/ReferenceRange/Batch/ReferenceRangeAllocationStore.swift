import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range allocations by code.
    protocol ReferenceRangeAllocationStore {
        func find(_ code: String) -> ReferenceRangeAllocation?
        func save(_ item: ReferenceRangeAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeAllocationStore: ReferenceRangeAllocationStore {
        var items: [String: ReferenceRangeAllocation]
        var order: [String]

        init(items: [String: ReferenceRangeAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeAllocation) {
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

        func list() -> [ReferenceRangeAllocation] {
            var out: [ReferenceRangeAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeAllocationStore() -> any ReferenceRangeAllocationStore {
        return MemoryReferenceRangeAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeAllocationStore: ReferenceRangeAllocationStore {
        var inner: MemoryReferenceRangeAllocationStore
        var cache: TTLCache<ReferenceRangeAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeAllocationStore, cache: TTLCache<ReferenceRangeAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeAllocation? {
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

        func save(_ item: ReferenceRangeAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeAllocation] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeAllocationStore(_ inner: MemoryReferenceRangeAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeAllocationStore {
        return CachedReferenceRangeAllocationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range allocations. Empty fields match all.
    final class ReferenceRangeAllocationQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeAllocation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ReferenceRangeAllocation]) -> [ReferenceRangeAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeAllocations(_ store: any ReferenceRangeAllocationStore, query: ReferenceRangeAllocationQuery) -> [ReferenceRangeAllocation] {
        return query.apply(store.list())
    }
}
