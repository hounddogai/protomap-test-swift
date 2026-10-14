import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps strict recall entries by code.
    protocol StrictRecallEntryStore {
        func find(_ code: String) -> StrictRecallEntry?
        func save(_ item: StrictRecallEntry)
        func remove(_ code: String) -> Bool
        func list() -> [StrictRecallEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictRecallEntryStore: StrictRecallEntryStore {
        var items: [String: StrictRecallEntry]
        var order: [String]

        init(items: [String: StrictRecallEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictRecallEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictRecallEntry) {
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

        func list() -> [StrictRecallEntry] {
            var out: [StrictRecallEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictRecallEntryStore() -> any StrictRecallEntryStore {
        return MemoryStrictRecallEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictRecallEntryStore: StrictRecallEntryStore {
        var inner: MemoryStrictRecallEntryStore
        var cache: TTLCache<StrictRecallEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictRecallEntryStore, cache: TTLCache<StrictRecallEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictRecallEntry? {
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

        func save(_ item: StrictRecallEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictRecallEntry] {
            return inner.list()
        }
    }

    static func newCachedStrictRecallEntryStore(_ inner: MemoryStrictRecallEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictRecallEntryStore {
        return CachedStrictRecallEntryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict recall entries. Empty fields match all.
    final class StrictRecallEntryQuery {
        var category: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictRecallEntry) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictRecallEntry]) -> [StrictRecallEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictRecallEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictRecallEntries(_ store: any StrictRecallEntryStore, query: StrictRecallEntryQuery) -> [StrictRecallEntry] {
        return query.apply(store.list())
    }
}
