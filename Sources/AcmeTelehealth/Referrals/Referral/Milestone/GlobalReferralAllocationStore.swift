import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps global referral allocations by code.
    protocol GlobalReferralAllocationStore {
        func find(_ code: String) -> GlobalReferralAllocation?
        func save(_ item: GlobalReferralAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalReferralAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalReferralAllocationStore: GlobalReferralAllocationStore {
        var items: [String: GlobalReferralAllocation]
        var order: [String]

        init(items: [String: GlobalReferralAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalReferralAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalReferralAllocation) {
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

        func list() -> [GlobalReferralAllocation] {
            var out: [GlobalReferralAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalReferralAllocationStore() -> any GlobalReferralAllocationStore {
        return MemoryGlobalReferralAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalReferralAllocationStore: GlobalReferralAllocationStore {
        var inner: MemoryGlobalReferralAllocationStore
        var cache: TTLCache<GlobalReferralAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalReferralAllocationStore, cache: TTLCache<GlobalReferralAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalReferralAllocation? {
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

        func save(_ item: GlobalReferralAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalReferralAllocation] {
            return inner.list()
        }
    }

    static func newCachedGlobalReferralAllocationStore(_ inner: MemoryGlobalReferralAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalReferralAllocationStore {
        return CachedGlobalReferralAllocationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global referral allocations. Empty fields match all.
    final class GlobalReferralAllocationQuery {
        var segment: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalReferralAllocation) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalReferralAllocation]) -> [GlobalReferralAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalReferralAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalReferralAllocations(_ store: any GlobalReferralAllocationStore, query: GlobalReferralAllocationQuery) -> [GlobalReferralAllocation] {
        return query.apply(store.list())
    }
}
