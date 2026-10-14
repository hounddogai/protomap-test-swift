import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps pending eligibility slots by code.
    protocol PendingEligibilitySlotStore {
        func find(_ code: String) -> PendingEligibilitySlot?
        func save(_ item: PendingEligibilitySlot)
        func remove(_ code: String) -> Bool
        func list() -> [PendingEligibilitySlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingEligibilitySlotStore: PendingEligibilitySlotStore {
        var items: [String: PendingEligibilitySlot]
        var order: [String]

        init(items: [String: PendingEligibilitySlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingEligibilitySlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingEligibilitySlot) {
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

        func list() -> [PendingEligibilitySlot] {
            var out: [PendingEligibilitySlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingEligibilitySlotStore() -> any PendingEligibilitySlotStore {
        return MemoryPendingEligibilitySlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingEligibilitySlotStore: PendingEligibilitySlotStore {
        var inner: MemoryPendingEligibilitySlotStore
        var cache: TTLCache<PendingEligibilitySlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingEligibilitySlotStore, cache: TTLCache<PendingEligibilitySlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingEligibilitySlot? {
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

        func save(_ item: PendingEligibilitySlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingEligibilitySlot] {
            return inner.list()
        }
    }

    static func newCachedPendingEligibilitySlotStore(_ inner: MemoryPendingEligibilitySlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingEligibilitySlotStore {
        return CachedPendingEligibilitySlotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending eligibility slots. Empty fields match all.
    final class PendingEligibilitySlotQuery {
        var country: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingEligibilitySlot) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingEligibilitySlot]) -> [PendingEligibilitySlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingEligibilitySlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingEligibilitySlots(_ store: any PendingEligibilitySlotStore, query: PendingEligibilitySlotQuery) -> [PendingEligibilitySlot] {
        return query.apply(store.list())
    }
}
