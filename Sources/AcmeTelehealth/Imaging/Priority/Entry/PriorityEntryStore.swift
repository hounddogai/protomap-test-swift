import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority entries by code.
    protocol PriorityEntryStore {
        func find(_ code: String) -> PriorityEntry?
        func save(_ item: PriorityEntry)
        func remove(_ code: String) -> Bool
        func list() -> [PriorityEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPriorityEntryStore: PriorityEntryStore {
        var items: [String: PriorityEntry]
        var order: [String]

        init(items: [String: PriorityEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PriorityEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PriorityEntry) {
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

        func list() -> [PriorityEntry] {
            var out: [PriorityEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPriorityEntryStore() -> any PriorityEntryStore {
        return MemoryPriorityEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPriorityEntryStore: PriorityEntryStore {
        var inner: MemoryPriorityEntryStore
        var cache: TTLCache<PriorityEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryPriorityEntryStore, cache: TTLCache<PriorityEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PriorityEntry? {
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

        func save(_ item: PriorityEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PriorityEntry] {
            return inner.list()
        }
    }

    static func newCachedPriorityEntryStore(_ inner: MemoryPriorityEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PriorityEntryStore {
        return CachedPriorityEntryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority entries. Empty fields match all.
    final class PriorityEntryQuery {
        var country: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PriorityEntry) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PriorityEntry]) -> [PriorityEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PriorityEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPriorityEntries(_ store: any PriorityEntryStore, query: PriorityEntryQuery) -> [PriorityEntry] {
        return query.apply(store.list())
    }
}
