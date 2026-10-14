import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap slots by code.
    protocol CareGapSlotStore {
        func find(_ code: String) -> CareGapSlot?
        func save(_ item: CareGapSlot)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapSlotStore: CareGapSlotStore {
        var items: [String: CareGapSlot]
        var order: [String]

        init(items: [String: CareGapSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapSlot) {
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

        func list() -> [CareGapSlot] {
            var out: [CareGapSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapSlotStore() -> any CareGapSlotStore {
        return MemoryCareGapSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapSlotStore: CareGapSlotStore {
        var inner: MemoryCareGapSlotStore
        var cache: TTLCache<CareGapSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapSlotStore, cache: TTLCache<CareGapSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapSlot? {
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

        func save(_ item: CareGapSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapSlot] {
            return inner.list()
        }
    }

    static func newCachedCareGapSlotStore(_ inner: MemoryCareGapSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapSlotStore {
        return CachedCareGapSlotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap slots. Empty fields match all.
    final class CareGapSlotQuery {
        var title: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapSlot) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareGapSlot]) -> [CareGapSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapSlots(_ store: any CareGapSlotStore, query: CareGapSlotQuery) -> [CareGapSlot] {
        return query.apply(store.list())
    }
}
