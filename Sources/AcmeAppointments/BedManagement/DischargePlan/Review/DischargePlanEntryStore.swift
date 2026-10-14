import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan entries by code.
    protocol DischargePlanEntryStore {
        func find(_ code: String) -> DischargePlanEntry?
        func save(_ item: DischargePlanEntry)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanEntryStore: DischargePlanEntryStore {
        var items: [String: DischargePlanEntry]
        var order: [String]

        init(items: [String: DischargePlanEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanEntry) {
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

        func list() -> [DischargePlanEntry] {
            var out: [DischargePlanEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanEntryStore() -> any DischargePlanEntryStore {
        return MemoryDischargePlanEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanEntryStore: DischargePlanEntryStore {
        var inner: MemoryDischargePlanEntryStore
        var cache: TTLCache<DischargePlanEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanEntryStore, cache: TTLCache<DischargePlanEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanEntry? {
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

        func save(_ item: DischargePlanEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanEntry] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanEntryStore(_ inner: MemoryDischargePlanEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanEntryStore {
        return CachedDischargePlanEntryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan entries. Empty fields match all.
    final class DischargePlanEntryQuery {
        var label: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanEntry) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DischargePlanEntry]) -> [DischargePlanEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanEntries(_ store: any DischargePlanEntryStore, query: DischargePlanEntryQuery) -> [DischargePlanEntry] {
        return query.apply(store.list())
    }
}
