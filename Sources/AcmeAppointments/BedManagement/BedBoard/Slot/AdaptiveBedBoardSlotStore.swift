import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps adaptive bed board slots by code.
    protocol AdaptiveBedBoardSlotStore {
        func find(_ code: String) -> AdaptiveBedBoardSlot?
        func save(_ item: AdaptiveBedBoardSlot)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveBedBoardSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveBedBoardSlotStore: AdaptiveBedBoardSlotStore {
        var items: [String: AdaptiveBedBoardSlot]
        var order: [String]

        init(items: [String: AdaptiveBedBoardSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveBedBoardSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveBedBoardSlot) {
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

        func list() -> [AdaptiveBedBoardSlot] {
            var out: [AdaptiveBedBoardSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveBedBoardSlotStore() -> any AdaptiveBedBoardSlotStore {
        return MemoryAdaptiveBedBoardSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveBedBoardSlotStore: AdaptiveBedBoardSlotStore {
        var inner: MemoryAdaptiveBedBoardSlotStore
        var cache: TTLCache<AdaptiveBedBoardSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveBedBoardSlotStore, cache: TTLCache<AdaptiveBedBoardSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveBedBoardSlot? {
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

        func save(_ item: AdaptiveBedBoardSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveBedBoardSlot] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveBedBoardSlotStore(_ inner: MemoryAdaptiveBedBoardSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveBedBoardSlotStore {
        return CachedAdaptiveBedBoardSlotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive bed board slots. Empty fields match all.
    final class AdaptiveBedBoardSlotQuery {
        var unit: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveBedBoardSlot) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveBedBoardSlot]) -> [AdaptiveBedBoardSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveBedBoardSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveBedBoardSlots(_ store: any AdaptiveBedBoardSlotStore, query: AdaptiveBedBoardSlotQuery) -> [AdaptiveBedBoardSlot] {
        return query.apply(store.list())
    }
}
