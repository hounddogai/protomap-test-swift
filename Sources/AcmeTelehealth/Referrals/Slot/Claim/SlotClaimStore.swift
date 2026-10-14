import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps slot claims by code.
    protocol SlotClaimStore {
        func find(_ code: String) -> SlotClaim?
        func save(_ item: SlotClaim)
        func remove(_ code: String) -> Bool
        func list() -> [SlotClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySlotClaimStore: SlotClaimStore {
        var items: [String: SlotClaim]
        var order: [String]

        init(items: [String: SlotClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SlotClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SlotClaim) {
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

        func list() -> [SlotClaim] {
            var out: [SlotClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySlotClaimStore() -> any SlotClaimStore {
        return MemorySlotClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSlotClaimStore: SlotClaimStore {
        var inner: MemorySlotClaimStore
        var cache: TTLCache<SlotClaim>
        var hits: Int
        var misses: Int

        init(inner: MemorySlotClaimStore, cache: TTLCache<SlotClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SlotClaim? {
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

        func save(_ item: SlotClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SlotClaim] {
            return inner.list()
        }
    }

    static func newCachedSlotClaimStore(_ inner: MemorySlotClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SlotClaimStore {
        return CachedSlotClaimStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects slot claims. Empty fields match all.
    final class SlotClaimQuery {
        var facility: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minBudget: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SlotClaim) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [SlotClaim]) -> [SlotClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SlotClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSlotClaims(_ store: any SlotClaimStore, query: SlotClaimQuery) -> [SlotClaim] {
        return query.apply(store.list())
    }
}
