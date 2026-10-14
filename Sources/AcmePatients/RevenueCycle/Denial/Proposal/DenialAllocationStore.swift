import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial allocations by code.
    protocol DenialAllocationStore {
        func find(_ code: String) -> DenialAllocation?
        func save(_ item: DenialAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [DenialAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialAllocationStore: DenialAllocationStore {
        var items: [String: DenialAllocation]
        var order: [String]

        init(items: [String: DenialAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialAllocation) {
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

        func list() -> [DenialAllocation] {
            var out: [DenialAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialAllocationStore() -> any DenialAllocationStore {
        return MemoryDenialAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialAllocationStore: DenialAllocationStore {
        var inner: MemoryDenialAllocationStore
        var cache: TTLCache<DenialAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialAllocationStore, cache: TTLCache<DenialAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialAllocation? {
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

        func save(_ item: DenialAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialAllocation] {
            return inner.list()
        }
    }

    static func newCachedDenialAllocationStore(_ inner: MemoryDenialAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialAllocationStore {
        return CachedDenialAllocationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial allocations. Empty fields match all.
    final class DenialAllocationQuery {
        var title: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialAllocation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DenialAllocation]) -> [DenialAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialAllocations(_ store: any DenialAllocationStore, query: DenialAllocationQuery) -> [DenialAllocation] {
        return query.apply(store.list())
    }
}
