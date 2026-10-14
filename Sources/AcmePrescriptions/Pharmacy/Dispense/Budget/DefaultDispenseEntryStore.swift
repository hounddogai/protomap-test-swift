import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps default dispense entries by code.
    protocol DefaultDispenseEntryStore {
        func find(_ code: String) -> DefaultDispenseEntry?
        func save(_ item: DefaultDispenseEntry)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultDispenseEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultDispenseEntryStore: DefaultDispenseEntryStore {
        var items: [String: DefaultDispenseEntry]
        var order: [String]

        init(items: [String: DefaultDispenseEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultDispenseEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultDispenseEntry) {
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

        func list() -> [DefaultDispenseEntry] {
            var out: [DefaultDispenseEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultDispenseEntryStore() -> any DefaultDispenseEntryStore {
        return MemoryDefaultDispenseEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultDispenseEntryStore: DefaultDispenseEntryStore {
        var inner: MemoryDefaultDispenseEntryStore
        var cache: TTLCache<DefaultDispenseEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultDispenseEntryStore, cache: TTLCache<DefaultDispenseEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultDispenseEntry? {
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

        func save(_ item: DefaultDispenseEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultDispenseEntry] {
            return inner.list()
        }
    }

    static func newCachedDefaultDispenseEntryStore(_ inner: MemoryDefaultDispenseEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultDispenseEntryStore {
        return CachedDefaultDispenseEntryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default dispense entries. Empty fields match all.
    final class DefaultDispenseEntryQuery {
        var name: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultDispenseEntry) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultDispenseEntry]) -> [DefaultDispenseEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultDispenseEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultDispenseEntries(_ store: any DefaultDispenseEntryStore, query: DefaultDispenseEntryQuery) -> [DefaultDispenseEntry] {
        return query.apply(store.list())
    }
}
