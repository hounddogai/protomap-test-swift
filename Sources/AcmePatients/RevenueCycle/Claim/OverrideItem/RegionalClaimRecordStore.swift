import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps regional claim records by code.
    protocol RegionalClaimRecordStore {
        func find(_ code: String) -> RegionalClaimRecord?
        func save(_ item: RegionalClaimRecord)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalClaimRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalClaimRecordStore: RegionalClaimRecordStore {
        var items: [String: RegionalClaimRecord]
        var order: [String]

        init(items: [String: RegionalClaimRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalClaimRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalClaimRecord) {
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

        func list() -> [RegionalClaimRecord] {
            var out: [RegionalClaimRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalClaimRecordStore() -> any RegionalClaimRecordStore {
        return MemoryRegionalClaimRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalClaimRecordStore: RegionalClaimRecordStore {
        var inner: MemoryRegionalClaimRecordStore
        var cache: TTLCache<RegionalClaimRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalClaimRecordStore, cache: TTLCache<RegionalClaimRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalClaimRecord? {
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

        func save(_ item: RegionalClaimRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalClaimRecord] {
            return inner.list()
        }
    }

    static func newCachedRegionalClaimRecordStore(_ inner: MemoryRegionalClaimRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalClaimRecordStore {
        return CachedRegionalClaimRecordStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional claim records. Empty fields match all.
    final class RegionalClaimRecordQuery {
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

        func matches(_ item: RegionalClaimRecord) -> Bool {
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

        func apply(_ items: [RegionalClaimRecord]) -> [RegionalClaimRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalClaimRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalClaimRecords(_ store: any RegionalClaimRecordStore, query: RegionalClaimRecordQuery) -> [RegionalClaimRecord] {
        return query.apply(store.list())
    }
}
