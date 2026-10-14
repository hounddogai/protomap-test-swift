import AcmePlatform
import Foundation

extension Consent {
    /// Keeps scheduled revocation slots by code.
    protocol ScheduledRevocationSlotStore {
        func find(_ code: String) -> ScheduledRevocationSlot?
        func save(_ item: ScheduledRevocationSlot)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledRevocationSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledRevocationSlotStore: ScheduledRevocationSlotStore {
        var items: [String: ScheduledRevocationSlot]
        var order: [String]

        init(items: [String: ScheduledRevocationSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledRevocationSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledRevocationSlot) {
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

        func list() -> [ScheduledRevocationSlot] {
            var out: [ScheduledRevocationSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledRevocationSlotStore() -> any ScheduledRevocationSlotStore {
        return MemoryScheduledRevocationSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledRevocationSlotStore: ScheduledRevocationSlotStore {
        var inner: MemoryScheduledRevocationSlotStore
        var cache: TTLCache<ScheduledRevocationSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledRevocationSlotStore, cache: TTLCache<ScheduledRevocationSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledRevocationSlot? {
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

        func save(_ item: ScheduledRevocationSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledRevocationSlot] {
            return inner.list()
        }
    }

    static func newCachedScheduledRevocationSlotStore(_ inner: MemoryScheduledRevocationSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledRevocationSlotStore {
        return CachedScheduledRevocationSlotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled revocation slots. Empty fields match all.
    final class ScheduledRevocationSlotQuery {
        var region: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledRevocationSlot) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledRevocationSlot]) -> [ScheduledRevocationSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledRevocationSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledRevocationSlots(_ store: any ScheduledRevocationSlotStore, query: ScheduledRevocationSlotQuery) -> [ScheduledRevocationSlot] {
        return query.apply(store.list())
    }
}
