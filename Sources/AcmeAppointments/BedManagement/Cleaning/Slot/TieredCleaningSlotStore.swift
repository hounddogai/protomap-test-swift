import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps tiered cleaning slots by code.
    protocol TieredCleaningSlotStore {
        func find(_ code: String) -> TieredCleaningSlot?
        func save(_ item: TieredCleaningSlot)
        func remove(_ code: String) -> Bool
        func list() -> [TieredCleaningSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredCleaningSlotStore: TieredCleaningSlotStore {
        var items: [String: TieredCleaningSlot]
        var order: [String]

        init(items: [String: TieredCleaningSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredCleaningSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredCleaningSlot) {
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

        func list() -> [TieredCleaningSlot] {
            var out: [TieredCleaningSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredCleaningSlotStore() -> any TieredCleaningSlotStore {
        return MemoryTieredCleaningSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredCleaningSlotStore: TieredCleaningSlotStore {
        var inner: MemoryTieredCleaningSlotStore
        var cache: TTLCache<TieredCleaningSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredCleaningSlotStore, cache: TTLCache<TieredCleaningSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredCleaningSlot? {
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

        func save(_ item: TieredCleaningSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredCleaningSlot] {
            return inner.list()
        }
    }

    static func newCachedTieredCleaningSlotStore(_ inner: MemoryTieredCleaningSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredCleaningSlotStore {
        return CachedTieredCleaningSlotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered cleaning slots. Empty fields match all.
    final class TieredCleaningSlotQuery {
        var category: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minRatio: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredCleaningSlot) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredCleaningSlot]) -> [TieredCleaningSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredCleaningSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredCleaningSlots(_ store: any TieredCleaningSlotStore, query: TieredCleaningSlotQuery) -> [TieredCleaningSlot] {
        return query.apply(store.list())
    }
}
