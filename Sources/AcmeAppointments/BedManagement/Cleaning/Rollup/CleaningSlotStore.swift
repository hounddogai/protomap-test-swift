import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning slots by code.
    protocol CleaningSlotStore {
        func find(_ code: String) -> CleaningSlot?
        func save(_ item: CleaningSlot)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningSlotStore: CleaningSlotStore {
        var items: [String: CleaningSlot]
        var order: [String]

        init(items: [String: CleaningSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningSlot) {
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

        func list() -> [CleaningSlot] {
            var out: [CleaningSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningSlotStore() -> any CleaningSlotStore {
        return MemoryCleaningSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningSlotStore: CleaningSlotStore {
        var inner: MemoryCleaningSlotStore
        var cache: TTLCache<CleaningSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningSlotStore, cache: TTLCache<CleaningSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningSlot? {
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

        func save(_ item: CleaningSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningSlot] {
            return inner.list()
        }
    }

    static func newCachedCleaningSlotStore(_ inner: MemoryCleaningSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningSlotStore {
        return CachedCleaningSlotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning slots. Empty fields match all.
    final class CleaningSlotQuery {
        var label: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMargin: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningSlot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningSlot]) -> [CleaningSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningSlots(_ store: any CleaningSlotStore, query: CleaningSlotQuery) -> [CleaningSlot] {
        return query.apply(store.list())
    }
}
