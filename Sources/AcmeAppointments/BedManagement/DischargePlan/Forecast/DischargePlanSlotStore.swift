import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan slots by code.
    protocol DischargePlanSlotStore {
        func find(_ code: String) -> DischargePlanSlot?
        func save(_ item: DischargePlanSlot)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanSlotStore: DischargePlanSlotStore {
        var items: [String: DischargePlanSlot]
        var order: [String]

        init(items: [String: DischargePlanSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanSlot) {
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

        func list() -> [DischargePlanSlot] {
            var out: [DischargePlanSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanSlotStore() -> any DischargePlanSlotStore {
        return MemoryDischargePlanSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanSlotStore: DischargePlanSlotStore {
        var inner: MemoryDischargePlanSlotStore
        var cache: TTLCache<DischargePlanSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanSlotStore, cache: TTLCache<DischargePlanSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanSlot? {
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

        func save(_ item: DischargePlanSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanSlot] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanSlotStore(_ inner: MemoryDischargePlanSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanSlotStore {
        return CachedDischargePlanSlotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan slots. Empty fields match all.
    final class DischargePlanSlotQuery {
        var name: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanSlot) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DischargePlanSlot]) -> [DischargePlanSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanSlots(_ store: any DischargePlanSlotStore, query: DischargePlanSlotQuery) -> [DischargePlanSlot] {
        return query.apply(store.list())
    }
}
