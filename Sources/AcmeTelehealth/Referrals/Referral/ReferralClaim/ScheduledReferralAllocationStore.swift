import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps scheduled referral allocations by code.
    protocol ScheduledReferralAllocationStore {
        func find(_ code: String) -> ScheduledReferralAllocation?
        func save(_ item: ScheduledReferralAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledReferralAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledReferralAllocationStore: ScheduledReferralAllocationStore {
        var items: [String: ScheduledReferralAllocation]
        var order: [String]

        init(items: [String: ScheduledReferralAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledReferralAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledReferralAllocation) {
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

        func list() -> [ScheduledReferralAllocation] {
            var out: [ScheduledReferralAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledReferralAllocationStore() -> any ScheduledReferralAllocationStore {
        return MemoryScheduledReferralAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledReferralAllocationStore: ScheduledReferralAllocationStore {
        var inner: MemoryScheduledReferralAllocationStore
        var cache: TTLCache<ScheduledReferralAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledReferralAllocationStore, cache: TTLCache<ScheduledReferralAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledReferralAllocation? {
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

        func save(_ item: ScheduledReferralAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledReferralAllocation] {
            return inner.list()
        }
    }

    static func newCachedScheduledReferralAllocationStore(_ inner: MemoryScheduledReferralAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledReferralAllocationStore {
        return CachedScheduledReferralAllocationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled referral allocations. Empty fields match all.
    final class ScheduledReferralAllocationQuery {
        var label: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledReferralAllocation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledReferralAllocation]) -> [ScheduledReferralAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledReferralAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledReferralAllocations(_ store: any ScheduledReferralAllocationStore, query: ScheduledReferralAllocationQuery) -> [ScheduledReferralAllocation] {
        return query.apply(store.list())
    }
}
