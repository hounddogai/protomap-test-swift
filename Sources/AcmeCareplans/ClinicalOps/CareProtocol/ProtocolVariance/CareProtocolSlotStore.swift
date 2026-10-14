import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps care protocol slots by code.
    protocol CareProtocolSlotStore {
        func find(_ code: String) -> CareProtocolSlot?
        func save(_ item: CareProtocolSlot)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolSlotStore: CareProtocolSlotStore {
        var items: [String: CareProtocolSlot]
        var order: [String]

        init(items: [String: CareProtocolSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolSlot) {
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

        func list() -> [CareProtocolSlot] {
            var out: [CareProtocolSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolSlotStore() -> any CareProtocolSlotStore {
        return MemoryCareProtocolSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolSlotStore: CareProtocolSlotStore {
        var inner: MemoryCareProtocolSlotStore
        var cache: TTLCache<CareProtocolSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolSlotStore, cache: TTLCache<CareProtocolSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolSlot? {
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

        func save(_ item: CareProtocolSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolSlot] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolSlotStore(_ inner: MemoryCareProtocolSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolSlotStore {
        return CachedCareProtocolSlotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol slots. Empty fields match all.
    final class CareProtocolSlotQuery {
        var title: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolSlot) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [CareProtocolSlot]) -> [CareProtocolSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolSlots(_ store: any CareProtocolSlotStore, query: CareProtocolSlotQuery) -> [CareProtocolSlot] {
        return query.apply(store.list())
    }
}
