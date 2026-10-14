import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps pending substitution allocations by code.
    protocol PendingSubstitutionAllocationStore {
        func find(_ code: String) -> PendingSubstitutionAllocation?
        func save(_ item: PendingSubstitutionAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [PendingSubstitutionAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingSubstitutionAllocationStore: PendingSubstitutionAllocationStore {
        var items: [String: PendingSubstitutionAllocation]
        var order: [String]

        init(items: [String: PendingSubstitutionAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingSubstitutionAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingSubstitutionAllocation) {
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

        func list() -> [PendingSubstitutionAllocation] {
            var out: [PendingSubstitutionAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingSubstitutionAllocationStore() -> any PendingSubstitutionAllocationStore {
        return MemoryPendingSubstitutionAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingSubstitutionAllocationStore: PendingSubstitutionAllocationStore {
        var inner: MemoryPendingSubstitutionAllocationStore
        var cache: TTLCache<PendingSubstitutionAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingSubstitutionAllocationStore, cache: TTLCache<PendingSubstitutionAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingSubstitutionAllocation? {
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

        func save(_ item: PendingSubstitutionAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingSubstitutionAllocation] {
            return inner.list()
        }
    }

    static func newCachedPendingSubstitutionAllocationStore(_ inner: MemoryPendingSubstitutionAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingSubstitutionAllocationStore {
        return CachedPendingSubstitutionAllocationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending substitution allocations. Empty fields match all.
    final class PendingSubstitutionAllocationQuery {
        var title: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRefills: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingSubstitutionAllocation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingSubstitutionAllocation]) -> [PendingSubstitutionAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingSubstitutionAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingSubstitutionAllocations(_ store: any PendingSubstitutionAllocationStore, query: PendingSubstitutionAllocationQuery) -> [PendingSubstitutionAllocation] {
        return query.apply(store.list())
    }
}
