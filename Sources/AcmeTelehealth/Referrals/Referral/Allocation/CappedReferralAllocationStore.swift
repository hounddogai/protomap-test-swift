import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps capped referral allocations by code.
    protocol CappedReferralAllocationStore {
        func find(_ code: String) -> CappedReferralAllocation?
        func save(_ item: CappedReferralAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [CappedReferralAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedReferralAllocationStore: CappedReferralAllocationStore {
        var items: [String: CappedReferralAllocation]
        var order: [String]

        init(items: [String: CappedReferralAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedReferralAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedReferralAllocation) {
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

        func list() -> [CappedReferralAllocation] {
            var out: [CappedReferralAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedReferralAllocationStore() -> any CappedReferralAllocationStore {
        return MemoryCappedReferralAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedReferralAllocationStore: CappedReferralAllocationStore {
        var inner: MemoryCappedReferralAllocationStore
        var cache: TTLCache<CappedReferralAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedReferralAllocationStore, cache: TTLCache<CappedReferralAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedReferralAllocation? {
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

        func save(_ item: CappedReferralAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedReferralAllocation] {
            return inner.list()
        }
    }

    static func newCachedCappedReferralAllocationStore(_ inner: MemoryCappedReferralAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedReferralAllocationStore {
        return CachedCappedReferralAllocationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped referral allocations. Empty fields match all.
    final class CappedReferralAllocationQuery {
        var name: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minBudget: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedReferralAllocation) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedReferralAllocation]) -> [CappedReferralAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedReferralAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedReferralAllocations(_ store: any CappedReferralAllocationStore, query: CappedReferralAllocationQuery) -> [CappedReferralAllocation] {
        return query.apply(store.list())
    }
}
