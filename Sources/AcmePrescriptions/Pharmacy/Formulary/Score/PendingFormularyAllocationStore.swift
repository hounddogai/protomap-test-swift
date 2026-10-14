import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps pending formulary allocations by code.
    protocol PendingFormularyAllocationStore {
        func find(_ code: String) -> PendingFormularyAllocation?
        func save(_ item: PendingFormularyAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [PendingFormularyAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingFormularyAllocationStore: PendingFormularyAllocationStore {
        var items: [String: PendingFormularyAllocation]
        var order: [String]

        init(items: [String: PendingFormularyAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingFormularyAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingFormularyAllocation) {
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

        func list() -> [PendingFormularyAllocation] {
            var out: [PendingFormularyAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingFormularyAllocationStore() -> any PendingFormularyAllocationStore {
        return MemoryPendingFormularyAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingFormularyAllocationStore: PendingFormularyAllocationStore {
        var inner: MemoryPendingFormularyAllocationStore
        var cache: TTLCache<PendingFormularyAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingFormularyAllocationStore, cache: TTLCache<PendingFormularyAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingFormularyAllocation? {
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

        func save(_ item: PendingFormularyAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingFormularyAllocation] {
            return inner.list()
        }
    }

    static func newCachedPendingFormularyAllocationStore(_ inner: MemoryPendingFormularyAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingFormularyAllocationStore {
        return CachedPendingFormularyAllocationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending formulary allocations. Empty fields match all.
    final class PendingFormularyAllocationQuery {
        var title: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMargin: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingFormularyAllocation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingFormularyAllocation]) -> [PendingFormularyAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingFormularyAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingFormularyAllocations(_ store: any PendingFormularyAllocationStore, query: PendingFormularyAllocationQuery) -> [PendingFormularyAllocation] {
        return query.apply(store.list())
    }
}
