import AcmePlatform
import Foundation

extension Consent {
    /// Keeps witness allocations by code.
    protocol WitnessAllocationStore {
        func find(_ code: String) -> WitnessAllocation?
        func save(_ item: WitnessAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [WitnessAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWitnessAllocationStore: WitnessAllocationStore {
        var items: [String: WitnessAllocation]
        var order: [String]

        init(items: [String: WitnessAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WitnessAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WitnessAllocation) {
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

        func list() -> [WitnessAllocation] {
            var out: [WitnessAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWitnessAllocationStore() -> any WitnessAllocationStore {
        return MemoryWitnessAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWitnessAllocationStore: WitnessAllocationStore {
        var inner: MemoryWitnessAllocationStore
        var cache: TTLCache<WitnessAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryWitnessAllocationStore, cache: TTLCache<WitnessAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WitnessAllocation? {
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

        func save(_ item: WitnessAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WitnessAllocation] {
            return inner.list()
        }
    }

    static func newCachedWitnessAllocationStore(_ inner: MemoryWitnessAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WitnessAllocationStore {
        return CachedWitnessAllocationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects witness allocations. Empty fields match all.
    final class WitnessAllocationQuery {
        var title: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WitnessAllocation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [WitnessAllocation]) -> [WitnessAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WitnessAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWitnessAllocations(_ store: any WitnessAllocationStore, query: WitnessAllocationQuery) -> [WitnessAllocation] {
        return query.apply(store.list())
    }
}
