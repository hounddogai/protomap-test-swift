import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation allocations by code.
    protocol RevocationAllocationStore {
        func find(_ code: String) -> RevocationAllocation?
        func save(_ item: RevocationAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationAllocationStore: RevocationAllocationStore {
        var items: [String: RevocationAllocation]
        var order: [String]

        init(items: [String: RevocationAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationAllocation) {
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

        func list() -> [RevocationAllocation] {
            var out: [RevocationAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationAllocationStore() -> any RevocationAllocationStore {
        return MemoryRevocationAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationAllocationStore: RevocationAllocationStore {
        var inner: MemoryRevocationAllocationStore
        var cache: TTLCache<RevocationAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationAllocationStore, cache: TTLCache<RevocationAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationAllocation? {
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

        func save(_ item: RevocationAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationAllocation] {
            return inner.list()
        }
    }

    static func newCachedRevocationAllocationStore(_ inner: MemoryRevocationAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationAllocationStore {
        return CachedRevocationAllocationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation allocations. Empty fields match all.
    final class RevocationAllocationQuery {
        var ward: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationAllocation) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RevocationAllocation]) -> [RevocationAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationAllocations(_ store: any RevocationAllocationStore, query: RevocationAllocationQuery) -> [RevocationAllocation] {
        return query.apply(store.list())
    }
}
