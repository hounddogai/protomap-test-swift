import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps weighted outreach slots by code.
    protocol WeightedOutreachSlotStore {
        func find(_ code: String) -> WeightedOutreachSlot?
        func save(_ item: WeightedOutreachSlot)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedOutreachSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedOutreachSlotStore: WeightedOutreachSlotStore {
        var items: [String: WeightedOutreachSlot]
        var order: [String]

        init(items: [String: WeightedOutreachSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedOutreachSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedOutreachSlot) {
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

        func list() -> [WeightedOutreachSlot] {
            var out: [WeightedOutreachSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedOutreachSlotStore() -> any WeightedOutreachSlotStore {
        return MemoryWeightedOutreachSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedOutreachSlotStore: WeightedOutreachSlotStore {
        var inner: MemoryWeightedOutreachSlotStore
        var cache: TTLCache<WeightedOutreachSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedOutreachSlotStore, cache: TTLCache<WeightedOutreachSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedOutreachSlot? {
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

        func save(_ item: WeightedOutreachSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedOutreachSlot] {
            return inner.list()
        }
    }

    static func newCachedWeightedOutreachSlotStore(_ inner: MemoryWeightedOutreachSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedOutreachSlotStore {
        return CachedWeightedOutreachSlotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted outreach slots. Empty fields match all.
    final class WeightedOutreachSlotQuery {
        var channel: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedOutreachSlot) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [WeightedOutreachSlot]) -> [WeightedOutreachSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedOutreachSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedOutreachSlots(_ store: any WeightedOutreachSlotStore, query: WeightedOutreachSlotQuery) -> [WeightedOutreachSlot] {
        return query.apply(store.list())
    }
}
