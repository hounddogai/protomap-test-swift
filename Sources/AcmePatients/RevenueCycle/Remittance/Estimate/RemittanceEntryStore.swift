import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance entries by code.
    protocol RemittanceEntryStore {
        func find(_ code: String) -> RemittanceEntry?
        func save(_ item: RemittanceEntry)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceEntryStore: RemittanceEntryStore {
        var items: [String: RemittanceEntry]
        var order: [String]

        init(items: [String: RemittanceEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceEntry) {
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

        func list() -> [RemittanceEntry] {
            var out: [RemittanceEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceEntryStore() -> any RemittanceEntryStore {
        return MemoryRemittanceEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceEntryStore: RemittanceEntryStore {
        var inner: MemoryRemittanceEntryStore
        var cache: TTLCache<RemittanceEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceEntryStore, cache: TTLCache<RemittanceEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceEntry? {
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

        func save(_ item: RemittanceEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceEntry] {
            return inner.list()
        }
    }

    static func newCachedRemittanceEntryStore(_ inner: MemoryRemittanceEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceEntryStore {
        return CachedRemittanceEntryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance entries. Empty fields match all.
    final class RemittanceEntryQuery {
        var name: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceEntry) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittanceEntry]) -> [RemittanceEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceEntries(_ store: any RemittanceEntryStore, query: RemittanceEntryQuery) -> [RemittanceEntry] {
        return query.apply(store.list())
    }
}
