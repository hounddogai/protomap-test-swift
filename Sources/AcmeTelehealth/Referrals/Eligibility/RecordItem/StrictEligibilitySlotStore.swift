import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps strict eligibility slots by code.
    protocol StrictEligibilitySlotStore {
        func find(_ code: String) -> StrictEligibilitySlot?
        func save(_ item: StrictEligibilitySlot)
        func remove(_ code: String) -> Bool
        func list() -> [StrictEligibilitySlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictEligibilitySlotStore: StrictEligibilitySlotStore {
        var items: [String: StrictEligibilitySlot]
        var order: [String]

        init(items: [String: StrictEligibilitySlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictEligibilitySlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictEligibilitySlot) {
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

        func list() -> [StrictEligibilitySlot] {
            var out: [StrictEligibilitySlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictEligibilitySlotStore() -> any StrictEligibilitySlotStore {
        return MemoryStrictEligibilitySlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictEligibilitySlotStore: StrictEligibilitySlotStore {
        var inner: MemoryStrictEligibilitySlotStore
        var cache: TTLCache<StrictEligibilitySlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictEligibilitySlotStore, cache: TTLCache<StrictEligibilitySlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictEligibilitySlot? {
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

        func save(_ item: StrictEligibilitySlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictEligibilitySlot] {
            return inner.list()
        }
    }

    static func newCachedStrictEligibilitySlotStore(_ inner: MemoryStrictEligibilitySlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictEligibilitySlotStore {
        return CachedStrictEligibilitySlotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict eligibility slots. Empty fields match all.
    final class StrictEligibilitySlotQuery {
        var name: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictEligibilitySlot) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictEligibilitySlot]) -> [StrictEligibilitySlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictEligibilitySlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictEligibilitySlots(_ store: any StrictEligibilitySlotStore, query: StrictEligibilitySlotQuery) -> [StrictEligibilitySlot] {
        return query.apply(store.list())
    }
}
