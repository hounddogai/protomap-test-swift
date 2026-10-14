import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps regional discharge plan allocations by code.
    protocol RegionalDischargePlanAllocationStore {
        func find(_ code: String) -> RegionalDischargePlanAllocation?
        func save(_ item: RegionalDischargePlanAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalDischargePlanAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalDischargePlanAllocationStore: RegionalDischargePlanAllocationStore {
        var items: [String: RegionalDischargePlanAllocation]
        var order: [String]

        init(items: [String: RegionalDischargePlanAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalDischargePlanAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalDischargePlanAllocation) {
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

        func list() -> [RegionalDischargePlanAllocation] {
            var out: [RegionalDischargePlanAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalDischargePlanAllocationStore() -> any RegionalDischargePlanAllocationStore {
        return MemoryRegionalDischargePlanAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalDischargePlanAllocationStore: RegionalDischargePlanAllocationStore {
        var inner: MemoryRegionalDischargePlanAllocationStore
        var cache: TTLCache<RegionalDischargePlanAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalDischargePlanAllocationStore, cache: TTLCache<RegionalDischargePlanAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalDischargePlanAllocation? {
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

        func save(_ item: RegionalDischargePlanAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalDischargePlanAllocation] {
            return inner.list()
        }
    }

    static func newCachedRegionalDischargePlanAllocationStore(_ inner: MemoryRegionalDischargePlanAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalDischargePlanAllocationStore {
        return CachedRegionalDischargePlanAllocationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional discharge plan allocations. Empty fields match all.
    final class RegionalDischargePlanAllocationQuery {
        var label: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalDischargePlanAllocation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalDischargePlanAllocation]) -> [RegionalDischargePlanAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalDischargePlanAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalDischargePlanAllocations(_ store: any RegionalDischargePlanAllocationStore, query: RegionalDischargePlanAllocationQuery) -> [RegionalDischargePlanAllocation] {
        return query.apply(store.list())
    }
}
