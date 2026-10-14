import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure entries by code.
    protocol DisclosureEntryStore {
        func find(_ code: String) -> DisclosureEntry?
        func save(_ item: DisclosureEntry)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureEntryStore: DisclosureEntryStore {
        var items: [String: DisclosureEntry]
        var order: [String]

        init(items: [String: DisclosureEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureEntry) {
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

        func list() -> [DisclosureEntry] {
            var out: [DisclosureEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureEntryStore() -> any DisclosureEntryStore {
        return MemoryDisclosureEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureEntryStore: DisclosureEntryStore {
        var inner: MemoryDisclosureEntryStore
        var cache: TTLCache<DisclosureEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureEntryStore, cache: TTLCache<DisclosureEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureEntry? {
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

        func save(_ item: DisclosureEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureEntry] {
            return inner.list()
        }
    }

    static func newCachedDisclosureEntryStore(_ inner: MemoryDisclosureEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureEntryStore {
        return CachedDisclosureEntryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure entries. Empty fields match all.
    final class DisclosureEntryQuery {
        var ward: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minMargin: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureEntry) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DisclosureEntry]) -> [DisclosureEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureEntries(_ store: any DisclosureEntryStore, query: DisclosureEntryQuery) -> [DisclosureEntry] {
        return query.apply(store.list())
    }
}
