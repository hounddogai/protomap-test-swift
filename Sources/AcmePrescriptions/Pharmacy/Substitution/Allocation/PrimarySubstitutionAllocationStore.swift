import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps primary substitution allocations by code.
    protocol PrimarySubstitutionAllocationStore {
        func find(_ code: String) -> PrimarySubstitutionAllocation?
        func save(_ item: PrimarySubstitutionAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [PrimarySubstitutionAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimarySubstitutionAllocationStore: PrimarySubstitutionAllocationStore {
        var items: [String: PrimarySubstitutionAllocation]
        var order: [String]

        init(items: [String: PrimarySubstitutionAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimarySubstitutionAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimarySubstitutionAllocation) {
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

        func list() -> [PrimarySubstitutionAllocation] {
            var out: [PrimarySubstitutionAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimarySubstitutionAllocationStore() -> any PrimarySubstitutionAllocationStore {
        return MemoryPrimarySubstitutionAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimarySubstitutionAllocationStore: PrimarySubstitutionAllocationStore {
        var inner: MemoryPrimarySubstitutionAllocationStore
        var cache: TTLCache<PrimarySubstitutionAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimarySubstitutionAllocationStore, cache: TTLCache<PrimarySubstitutionAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimarySubstitutionAllocation? {
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

        func save(_ item: PrimarySubstitutionAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimarySubstitutionAllocation] {
            return inner.list()
        }
    }

    static func newCachedPrimarySubstitutionAllocationStore(_ inner: MemoryPrimarySubstitutionAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimarySubstitutionAllocationStore {
        return CachedPrimarySubstitutionAllocationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary substitution allocations. Empty fields match all.
    final class PrimarySubstitutionAllocationQuery {
        var ward: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minLimit: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimarySubstitutionAllocation) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimarySubstitutionAllocation]) -> [PrimarySubstitutionAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimarySubstitutionAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimarySubstitutionAllocations(_ store: any PrimarySubstitutionAllocationStore, query: PrimarySubstitutionAllocationQuery) -> [PrimarySubstitutionAllocation] {
        return query.apply(store.list())
    }
}
