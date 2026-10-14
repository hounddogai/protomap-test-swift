import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense entries by code.
    protocol DispenseEntryStore {
        func find(_ code: String) -> DispenseEntry?
        func save(_ item: DispenseEntry)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseEntryStore: DispenseEntryStore {
        var items: [String: DispenseEntry]
        var order: [String]

        init(items: [String: DispenseEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseEntry) {
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

        func list() -> [DispenseEntry] {
            var out: [DispenseEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseEntryStore() -> any DispenseEntryStore {
        return MemoryDispenseEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseEntryStore: DispenseEntryStore {
        var inner: MemoryDispenseEntryStore
        var cache: TTLCache<DispenseEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseEntryStore, cache: TTLCache<DispenseEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseEntry? {
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

        func save(_ item: DispenseEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseEntry] {
            return inner.list()
        }
    }

    static func newCachedDispenseEntryStore(_ inner: MemoryDispenseEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseEntryStore {
        return CachedDispenseEntryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense entries. Empty fields match all.
    final class DispenseEntryQuery {
        var title: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseEntry) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseEntry]) -> [DispenseEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseEntries(_ store: any DispenseEntryStore, query: DispenseEntryQuery) -> [DispenseEntry] {
        return query.apply(store.list())
    }
}
