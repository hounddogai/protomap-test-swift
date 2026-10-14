import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps strict shift entries by code.
    protocol StrictShiftEntryStore {
        func find(_ code: String) -> StrictShiftEntry?
        func save(_ item: StrictShiftEntry)
        func remove(_ code: String) -> Bool
        func list() -> [StrictShiftEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictShiftEntryStore: StrictShiftEntryStore {
        var items: [String: StrictShiftEntry]
        var order: [String]

        init(items: [String: StrictShiftEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictShiftEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictShiftEntry) {
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

        func list() -> [StrictShiftEntry] {
            var out: [StrictShiftEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictShiftEntryStore() -> any StrictShiftEntryStore {
        return MemoryStrictShiftEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictShiftEntryStore: StrictShiftEntryStore {
        var inner: MemoryStrictShiftEntryStore
        var cache: TTLCache<StrictShiftEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictShiftEntryStore, cache: TTLCache<StrictShiftEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictShiftEntry? {
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

        func save(_ item: StrictShiftEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictShiftEntry] {
            return inner.list()
        }
    }

    static func newCachedStrictShiftEntryStore(_ inner: MemoryStrictShiftEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictShiftEntryStore {
        return CachedStrictShiftEntryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict shift entries. Empty fields match all.
    final class StrictShiftEntryQuery {
        var name: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCost: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictShiftEntry) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictShiftEntry]) -> [StrictShiftEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictShiftEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictShiftEntries(_ store: any StrictShiftEntryStore, query: StrictShiftEntryQuery) -> [StrictShiftEntry] {
        return query.apply(store.list())
    }
}
