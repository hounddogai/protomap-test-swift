import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps regional charge entries by code.
    protocol RegionalChargeEntryStore {
        func find(_ code: String) -> RegionalChargeEntry?
        func save(_ item: RegionalChargeEntry)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalChargeEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalChargeEntryStore: RegionalChargeEntryStore {
        var items: [String: RegionalChargeEntry]
        var order: [String]

        init(items: [String: RegionalChargeEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalChargeEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalChargeEntry) {
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

        func list() -> [RegionalChargeEntry] {
            var out: [RegionalChargeEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalChargeEntryStore() -> any RegionalChargeEntryStore {
        return MemoryRegionalChargeEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalChargeEntryStore: RegionalChargeEntryStore {
        var inner: MemoryRegionalChargeEntryStore
        var cache: TTLCache<RegionalChargeEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalChargeEntryStore, cache: TTLCache<RegionalChargeEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalChargeEntry? {
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

        func save(_ item: RegionalChargeEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalChargeEntry] {
            return inner.list()
        }
    }

    static func newCachedRegionalChargeEntryStore(_ inner: MemoryRegionalChargeEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalChargeEntryStore {
        return CachedRegionalChargeEntryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional charge entries. Empty fields match all.
    final class RegionalChargeEntryQuery {
        var region: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minRetries: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalChargeEntry) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalChargeEntry]) -> [RegionalChargeEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalChargeEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalChargeEntries(_ store: any RegionalChargeEntryStore, query: RegionalChargeEntryQuery) -> [RegionalChargeEntry] {
        return query.apply(store.list())
    }
}
