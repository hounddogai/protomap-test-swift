import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap allocations by code.
    protocol CareGapAllocationStore {
        func find(_ code: String) -> CareGapAllocation?
        func save(_ item: CareGapAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapAllocationStore: CareGapAllocationStore {
        var items: [String: CareGapAllocation]
        var order: [String]

        init(items: [String: CareGapAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapAllocation) {
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

        func list() -> [CareGapAllocation] {
            var out: [CareGapAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapAllocationStore() -> any CareGapAllocationStore {
        return MemoryCareGapAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapAllocationStore: CareGapAllocationStore {
        var inner: MemoryCareGapAllocationStore
        var cache: TTLCache<CareGapAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapAllocationStore, cache: TTLCache<CareGapAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapAllocation? {
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

        func save(_ item: CareGapAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapAllocation] {
            return inner.list()
        }
    }

    static func newCachedCareGapAllocationStore(_ inner: MemoryCareGapAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapAllocationStore {
        return CachedCareGapAllocationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap allocations. Empty fields match all.
    final class CareGapAllocationQuery {
        var ward: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapAllocation) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [CareGapAllocation]) -> [CareGapAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapAllocations(_ store: any CareGapAllocationStore, query: CareGapAllocationQuery) -> [CareGapAllocation] {
        return query.apply(store.list())
    }
}
