import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps slot rollups by code.
    protocol SlotRollupStore {
        func find(_ code: String) -> SlotRollup?
        func save(_ item: SlotRollup)
        func remove(_ code: String) -> Bool
        func list() -> [SlotRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySlotRollupStore: SlotRollupStore {
        var items: [String: SlotRollup]
        var order: [String]

        init(items: [String: SlotRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SlotRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SlotRollup) {
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

        func list() -> [SlotRollup] {
            var out: [SlotRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySlotRollupStore() -> any SlotRollupStore {
        return MemorySlotRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSlotRollupStore: SlotRollupStore {
        var inner: MemorySlotRollupStore
        var cache: TTLCache<SlotRollup>
        var hits: Int
        var misses: Int

        init(inner: MemorySlotRollupStore, cache: TTLCache<SlotRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SlotRollup? {
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

        func save(_ item: SlotRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SlotRollup] {
            return inner.list()
        }
    }

    static func newCachedSlotRollupStore(_ inner: MemorySlotRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SlotRollupStore {
        return CachedSlotRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects slot rollups. Empty fields match all.
    final class SlotRollupQuery {
        var segment: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minCost: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SlotRollup) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SlotRollup]) -> [SlotRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SlotRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSlotRollups(_ store: any SlotRollupStore, query: SlotRollupQuery) -> [SlotRollup] {
        return query.apply(store.list())
    }
}
