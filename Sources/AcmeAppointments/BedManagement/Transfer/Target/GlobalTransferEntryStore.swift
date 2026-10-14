import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps global transfer entries by code.
    protocol GlobalTransferEntryStore {
        func find(_ code: String) -> GlobalTransferEntry?
        func save(_ item: GlobalTransferEntry)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalTransferEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalTransferEntryStore: GlobalTransferEntryStore {
        var items: [String: GlobalTransferEntry]
        var order: [String]

        init(items: [String: GlobalTransferEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalTransferEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalTransferEntry) {
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

        func list() -> [GlobalTransferEntry] {
            var out: [GlobalTransferEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalTransferEntryStore() -> any GlobalTransferEntryStore {
        return MemoryGlobalTransferEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalTransferEntryStore: GlobalTransferEntryStore {
        var inner: MemoryGlobalTransferEntryStore
        var cache: TTLCache<GlobalTransferEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalTransferEntryStore, cache: TTLCache<GlobalTransferEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalTransferEntry? {
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

        func save(_ item: GlobalTransferEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalTransferEntry] {
            return inner.list()
        }
    }

    static func newCachedGlobalTransferEntryStore(_ inner: MemoryGlobalTransferEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalTransferEntryStore {
        return CachedGlobalTransferEntryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global transfer entries. Empty fields match all.
    final class GlobalTransferEntryQuery {
        var locale: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalTransferEntry) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [GlobalTransferEntry]) -> [GlobalTransferEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalTransferEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalTransferEntries(_ store: any GlobalTransferEntryStore, query: GlobalTransferEntryQuery) -> [GlobalTransferEntry] {
        return query.apply(store.list())
    }
}
