import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps rolling credential allocations by code.
    protocol RollingCredentialAllocationStore {
        func find(_ code: String) -> RollingCredentialAllocation?
        func save(_ item: RollingCredentialAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [RollingCredentialAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingCredentialAllocationStore: RollingCredentialAllocationStore {
        var items: [String: RollingCredentialAllocation]
        var order: [String]

        init(items: [String: RollingCredentialAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingCredentialAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingCredentialAllocation) {
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

        func list() -> [RollingCredentialAllocation] {
            var out: [RollingCredentialAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingCredentialAllocationStore() -> any RollingCredentialAllocationStore {
        return MemoryRollingCredentialAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingCredentialAllocationStore: RollingCredentialAllocationStore {
        var inner: MemoryRollingCredentialAllocationStore
        var cache: TTLCache<RollingCredentialAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingCredentialAllocationStore, cache: TTLCache<RollingCredentialAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingCredentialAllocation? {
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

        func save(_ item: RollingCredentialAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingCredentialAllocation] {
            return inner.list()
        }
    }

    static func newCachedRollingCredentialAllocationStore(_ inner: MemoryRollingCredentialAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingCredentialAllocationStore {
        return CachedRollingCredentialAllocationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling credential allocations. Empty fields match all.
    final class RollingCredentialAllocationQuery {
        var source: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingCredentialAllocation) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [RollingCredentialAllocation]) -> [RollingCredentialAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingCredentialAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingCredentialAllocations(_ store: any RollingCredentialAllocationStore, query: RollingCredentialAllocationQuery) -> [RollingCredentialAllocation] {
        return query.apply(store.list())
    }
}
