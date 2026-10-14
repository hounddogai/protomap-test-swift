import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure allocations by code.
    protocol ClosureAllocationStore {
        func find(_ code: String) -> ClosureAllocation?
        func save(_ item: ClosureAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureAllocationStore: ClosureAllocationStore {
        var items: [String: ClosureAllocation]
        var order: [String]

        init(items: [String: ClosureAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureAllocation) {
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

        func list() -> [ClosureAllocation] {
            var out: [ClosureAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureAllocationStore() -> any ClosureAllocationStore {
        return MemoryClosureAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureAllocationStore: ClosureAllocationStore {
        var inner: MemoryClosureAllocationStore
        var cache: TTLCache<ClosureAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureAllocationStore, cache: TTLCache<ClosureAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureAllocation? {
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

        func save(_ item: ClosureAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureAllocation] {
            return inner.list()
        }
    }

    static func newCachedClosureAllocationStore(_ inner: MemoryClosureAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureAllocationStore {
        return CachedClosureAllocationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure allocations. Empty fields match all.
    final class ClosureAllocationQuery {
        var locale: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosureAllocation) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClosureAllocation]) -> [ClosureAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureAllocations(_ store: any ClosureAllocationStore, query: ClosureAllocationQuery) -> [ClosureAllocation] {
        return query.apply(store.list())
    }
}
