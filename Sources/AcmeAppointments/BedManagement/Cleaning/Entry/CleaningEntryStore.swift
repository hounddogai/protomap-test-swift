import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning entries by code.
    protocol CleaningEntryStore {
        func find(_ code: String) -> CleaningEntry?
        func save(_ item: CleaningEntry)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningEntryStore: CleaningEntryStore {
        var items: [String: CleaningEntry]
        var order: [String]

        init(items: [String: CleaningEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningEntry) {
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

        func list() -> [CleaningEntry] {
            var out: [CleaningEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningEntryStore() -> any CleaningEntryStore {
        return MemoryCleaningEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningEntryStore: CleaningEntryStore {
        var inner: MemoryCleaningEntryStore
        var cache: TTLCache<CleaningEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningEntryStore, cache: TTLCache<CleaningEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningEntry? {
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

        func save(_ item: CleaningEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningEntry] {
            return inner.list()
        }
    }

    static func newCachedCleaningEntryStore(_ inner: MemoryCleaningEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningEntryStore {
        return CachedCleaningEntryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning entries. Empty fields match all.
    final class CleaningEntryQuery {
        var category: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minBudget: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningEntry) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningEntry]) -> [CleaningEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningEntries(_ store: any CleaningEntryStore, query: CleaningEntryQuery) -> [CleaningEntry] {
        return query.apply(store.list())
    }
}
