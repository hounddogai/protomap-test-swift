import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps global read slots by code.
    protocol GlobalReadSlotStore {
        func find(_ code: String) -> GlobalReadSlot?
        func save(_ item: GlobalReadSlot)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalReadSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalReadSlotStore: GlobalReadSlotStore {
        var items: [String: GlobalReadSlot]
        var order: [String]

        init(items: [String: GlobalReadSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalReadSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalReadSlot) {
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

        func list() -> [GlobalReadSlot] {
            var out: [GlobalReadSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalReadSlotStore() -> any GlobalReadSlotStore {
        return MemoryGlobalReadSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalReadSlotStore: GlobalReadSlotStore {
        var inner: MemoryGlobalReadSlotStore
        var cache: TTLCache<GlobalReadSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalReadSlotStore, cache: TTLCache<GlobalReadSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalReadSlot? {
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

        func save(_ item: GlobalReadSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalReadSlot] {
            return inner.list()
        }
    }

    static func newCachedGlobalReadSlotStore(_ inner: MemoryGlobalReadSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalReadSlotStore {
        return CachedGlobalReadSlotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global read slots. Empty fields match all.
    final class GlobalReadSlotQuery {
        var segment: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalReadSlot) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalReadSlot]) -> [GlobalReadSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalReadSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalReadSlots(_ store: any GlobalReadSlotStore, query: GlobalReadSlotQuery) -> [GlobalReadSlot] {
        return query.apply(store.list())
    }
}
