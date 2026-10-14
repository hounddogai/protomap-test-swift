import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps census entries by code.
    protocol CensusEntryStore {
        func find(_ code: String) -> CensusEntry?
        func save(_ item: CensusEntry)
        func remove(_ code: String) -> Bool
        func list() -> [CensusEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCensusEntryStore: CensusEntryStore {
        var items: [String: CensusEntry]
        var order: [String]

        init(items: [String: CensusEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CensusEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CensusEntry) {
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

        func list() -> [CensusEntry] {
            var out: [CensusEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCensusEntryStore() -> any CensusEntryStore {
        return MemoryCensusEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCensusEntryStore: CensusEntryStore {
        var inner: MemoryCensusEntryStore
        var cache: TTLCache<CensusEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryCensusEntryStore, cache: TTLCache<CensusEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CensusEntry? {
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

        func save(_ item: CensusEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CensusEntry] {
            return inner.list()
        }
    }

    static func newCachedCensusEntryStore(_ inner: MemoryCensusEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CensusEntryStore {
        return CachedCensusEntryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects census entries. Empty fields match all.
    final class CensusEntryQuery {
        var name: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CensusEntry) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CensusEntry]) -> [CensusEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CensusEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCensusEntries(_ store: any CensusEntryStore, query: CensusEntryQuery) -> [CensusEntry] {
        return query.apply(store.list())
    }
}
