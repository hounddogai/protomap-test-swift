import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime slots by code.
    protocol OvertimeSlotStore {
        func find(_ code: String) -> OvertimeSlot?
        func save(_ item: OvertimeSlot)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeSlotStore: OvertimeSlotStore {
        var items: [String: OvertimeSlot]
        var order: [String]

        init(items: [String: OvertimeSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeSlot) {
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

        func list() -> [OvertimeSlot] {
            var out: [OvertimeSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeSlotStore() -> any OvertimeSlotStore {
        return MemoryOvertimeSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeSlotStore: OvertimeSlotStore {
        var inner: MemoryOvertimeSlotStore
        var cache: TTLCache<OvertimeSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeSlotStore, cache: TTLCache<OvertimeSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeSlot? {
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

        func save(_ item: OvertimeSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeSlot] {
            return inner.list()
        }
    }

    static func newCachedOvertimeSlotStore(_ inner: MemoryOvertimeSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeSlotStore {
        return CachedOvertimeSlotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime slots. Empty fields match all.
    final class OvertimeSlotQuery {
        var name: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minScore: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeSlot) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OvertimeSlot]) -> [OvertimeSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeSlots(_ store: any OvertimeSlotStore, query: OvertimeSlotQuery) -> [OvertimeSlot] {
        return query.apply(store.list())
    }
}
