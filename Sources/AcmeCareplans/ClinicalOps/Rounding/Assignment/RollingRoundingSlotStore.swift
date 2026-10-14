import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rolling rounding slots by code.
    protocol RollingRoundingSlotStore {
        func find(_ code: String) -> RollingRoundingSlot?
        func save(_ item: RollingRoundingSlot)
        func remove(_ code: String) -> Bool
        func list() -> [RollingRoundingSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingRoundingSlotStore: RollingRoundingSlotStore {
        var items: [String: RollingRoundingSlot]
        var order: [String]

        init(items: [String: RollingRoundingSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingRoundingSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingRoundingSlot) {
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

        func list() -> [RollingRoundingSlot] {
            var out: [RollingRoundingSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingRoundingSlotStore() -> any RollingRoundingSlotStore {
        return MemoryRollingRoundingSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingRoundingSlotStore: RollingRoundingSlotStore {
        var inner: MemoryRollingRoundingSlotStore
        var cache: TTLCache<RollingRoundingSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingRoundingSlotStore, cache: TTLCache<RollingRoundingSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingRoundingSlot? {
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

        func save(_ item: RollingRoundingSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingRoundingSlot] {
            return inner.list()
        }
    }

    static func newCachedRollingRoundingSlotStore(_ inner: MemoryRollingRoundingSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingRoundingSlotStore {
        return CachedRollingRoundingSlotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling rounding slots. Empty fields match all.
    final class RollingRoundingSlotQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingRoundingSlot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingRoundingSlot]) -> [RollingRoundingSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingRoundingSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingRoundingSlots(_ store: any RollingRoundingSlotStore, query: RollingRoundingSlotQuery) -> [RollingRoundingSlot] {
        return query.apply(store.list())
    }
}
