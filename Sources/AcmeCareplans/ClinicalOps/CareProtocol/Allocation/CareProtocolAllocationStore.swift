import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps care protocol allocations by code.
    protocol CareProtocolAllocationStore {
        func find(_ code: String) -> CareProtocolAllocation?
        func save(_ item: CareProtocolAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolAllocationStore: CareProtocolAllocationStore {
        var items: [String: CareProtocolAllocation]
        var order: [String]

        init(items: [String: CareProtocolAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolAllocation) {
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

        func list() -> [CareProtocolAllocation] {
            var out: [CareProtocolAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolAllocationStore() -> any CareProtocolAllocationStore {
        return MemoryCareProtocolAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolAllocationStore: CareProtocolAllocationStore {
        var inner: MemoryCareProtocolAllocationStore
        var cache: TTLCache<CareProtocolAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolAllocationStore, cache: TTLCache<CareProtocolAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolAllocation? {
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

        func save(_ item: CareProtocolAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolAllocation] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolAllocationStore(_ inner: MemoryCareProtocolAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolAllocationStore {
        return CachedCareProtocolAllocationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol allocations. Empty fields match all.
    final class CareProtocolAllocationQuery {
        var facility: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolAllocation) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolAllocation]) -> [CareProtocolAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolAllocations(_ store: any CareProtocolAllocationStore, query: CareProtocolAllocationQuery) -> [CareProtocolAllocation] {
        return query.apply(store.list())
    }
}
