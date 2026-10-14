import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps global census slots by code.
    protocol GlobalCensusSlotStore {
        func find(_ code: String) -> GlobalCensusSlot?
        func save(_ item: GlobalCensusSlot)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalCensusSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalCensusSlotStore: GlobalCensusSlotStore {
        var items: [String: GlobalCensusSlot]
        var order: [String]

        init(items: [String: GlobalCensusSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalCensusSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalCensusSlot) {
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

        func list() -> [GlobalCensusSlot] {
            var out: [GlobalCensusSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalCensusSlotStore() -> any GlobalCensusSlotStore {
        return MemoryGlobalCensusSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalCensusSlotStore: GlobalCensusSlotStore {
        var inner: MemoryGlobalCensusSlotStore
        var cache: TTLCache<GlobalCensusSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalCensusSlotStore, cache: TTLCache<GlobalCensusSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalCensusSlot? {
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

        func save(_ item: GlobalCensusSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalCensusSlot] {
            return inner.list()
        }
    }

    static func newCachedGlobalCensusSlotStore(_ inner: MemoryGlobalCensusSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalCensusSlotStore {
        return CachedGlobalCensusSlotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global census slots. Empty fields match all.
    final class GlobalCensusSlotQuery {
        var locale: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalCensusSlot) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalCensusSlot]) -> [GlobalCensusSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalCensusSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalCensusSlots(_ store: any GlobalCensusSlotStore, query: GlobalCensusSlotQuery) -> [GlobalCensusSlot] {
        return query.apply(store.list())
    }
}
