import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps formulary allocations by code.
    protocol FormularyAllocationStore {
        func find(_ code: String) -> FormularyAllocation?
        func save(_ item: FormularyAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [FormularyAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFormularyAllocationStore: FormularyAllocationStore {
        var items: [String: FormularyAllocation]
        var order: [String]

        init(items: [String: FormularyAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FormularyAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FormularyAllocation) {
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

        func list() -> [FormularyAllocation] {
            var out: [FormularyAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFormularyAllocationStore() -> any FormularyAllocationStore {
        return MemoryFormularyAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFormularyAllocationStore: FormularyAllocationStore {
        var inner: MemoryFormularyAllocationStore
        var cache: TTLCache<FormularyAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryFormularyAllocationStore, cache: TTLCache<FormularyAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FormularyAllocation? {
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

        func save(_ item: FormularyAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FormularyAllocation] {
            return inner.list()
        }
    }

    static func newCachedFormularyAllocationStore(_ inner: MemoryFormularyAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FormularyAllocationStore {
        return CachedFormularyAllocationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects formulary allocations. Empty fields match all.
    final class FormularyAllocationQuery {
        var label: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minAmount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FormularyAllocation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FormularyAllocation]) -> [FormularyAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FormularyAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFormularyAllocations(_ store: any FormularyAllocationStore, query: FormularyAllocationQuery) -> [FormularyAllocation] {
        return query.apply(store.list())
    }
}
