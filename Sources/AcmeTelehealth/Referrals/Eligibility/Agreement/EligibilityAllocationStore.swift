import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility allocations by code.
    protocol EligibilityAllocationStore {
        func find(_ code: String) -> EligibilityAllocation?
        func save(_ item: EligibilityAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityAllocationStore: EligibilityAllocationStore {
        var items: [String: EligibilityAllocation]
        var order: [String]

        init(items: [String: EligibilityAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityAllocation) {
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

        func list() -> [EligibilityAllocation] {
            var out: [EligibilityAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityAllocationStore() -> any EligibilityAllocationStore {
        return MemoryEligibilityAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityAllocationStore: EligibilityAllocationStore {
        var inner: MemoryEligibilityAllocationStore
        var cache: TTLCache<EligibilityAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityAllocationStore, cache: TTLCache<EligibilityAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityAllocation? {
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

        func save(_ item: EligibilityAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityAllocation] {
            return inner.list()
        }
    }

    static func newCachedEligibilityAllocationStore(_ inner: MemoryEligibilityAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityAllocationStore {
        return CachedEligibilityAllocationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility allocations. Empty fields match all.
    final class EligibilityAllocationQuery {
        var country: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minAmount: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilityAllocation) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [EligibilityAllocation]) -> [EligibilityAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityAllocations(_ store: any EligibilityAllocationStore, query: EligibilityAllocationQuery) -> [EligibilityAllocation] {
        return query.apply(store.list())
    }
}
