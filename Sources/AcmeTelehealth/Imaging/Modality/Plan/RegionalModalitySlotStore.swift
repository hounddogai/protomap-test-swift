import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps regional modality slots by code.
    protocol RegionalModalitySlotStore {
        func find(_ code: String) -> RegionalModalitySlot?
        func save(_ item: RegionalModalitySlot)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalModalitySlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalModalitySlotStore: RegionalModalitySlotStore {
        var items: [String: RegionalModalitySlot]
        var order: [String]

        init(items: [String: RegionalModalitySlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalModalitySlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalModalitySlot) {
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

        func list() -> [RegionalModalitySlot] {
            var out: [RegionalModalitySlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalModalitySlotStore() -> any RegionalModalitySlotStore {
        return MemoryRegionalModalitySlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalModalitySlotStore: RegionalModalitySlotStore {
        var inner: MemoryRegionalModalitySlotStore
        var cache: TTLCache<RegionalModalitySlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalModalitySlotStore, cache: TTLCache<RegionalModalitySlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalModalitySlot? {
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

        func save(_ item: RegionalModalitySlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalModalitySlot] {
            return inner.list()
        }
    }

    static func newCachedRegionalModalitySlotStore(_ inner: MemoryRegionalModalitySlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalModalitySlotStore {
        return CachedRegionalModalitySlotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional modality slots. Empty fields match all.
    final class RegionalModalitySlotQuery {
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

        func matches(_ item: RegionalModalitySlot) -> Bool {
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

        func apply(_ items: [RegionalModalitySlot]) -> [RegionalModalitySlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalModalitySlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalModalitySlots(_ store: any RegionalModalitySlotStore, query: RegionalModalitySlotQuery) -> [RegionalModalitySlot] {
        return query.apply(store.list())
    }
}
