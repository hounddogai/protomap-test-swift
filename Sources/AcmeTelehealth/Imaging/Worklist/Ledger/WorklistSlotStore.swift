import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist slots by code.
    protocol WorklistSlotStore {
        func find(_ code: String) -> WorklistSlot?
        func save(_ item: WorklistSlot)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistSlotStore: WorklistSlotStore {
        var items: [String: WorklistSlot]
        var order: [String]

        init(items: [String: WorklistSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistSlot) {
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

        func list() -> [WorklistSlot] {
            var out: [WorklistSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistSlotStore() -> any WorklistSlotStore {
        return MemoryWorklistSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistSlotStore: WorklistSlotStore {
        var inner: MemoryWorklistSlotStore
        var cache: TTLCache<WorklistSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistSlotStore, cache: TTLCache<WorklistSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistSlot? {
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

        func save(_ item: WorklistSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistSlot] {
            return inner.list()
        }
    }

    static func newCachedWorklistSlotStore(_ inner: MemoryWorklistSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistSlotStore {
        return CachedWorklistSlotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist slots. Empty fields match all.
    final class WorklistSlotQuery {
        var name: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistSlot) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WorklistSlot]) -> [WorklistSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistSlots(_ store: any WorklistSlotStore, query: WorklistSlotQuery) -> [WorklistSlot] {
        return query.apply(store.list())
    }
}
