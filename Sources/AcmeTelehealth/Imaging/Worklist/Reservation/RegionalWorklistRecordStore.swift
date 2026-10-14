import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps regional worklist records by code.
    protocol RegionalWorklistRecordStore {
        func find(_ code: String) -> RegionalWorklistRecord?
        func save(_ item: RegionalWorklistRecord)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalWorklistRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalWorklistRecordStore: RegionalWorklistRecordStore {
        var items: [String: RegionalWorklistRecord]
        var order: [String]

        init(items: [String: RegionalWorklistRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalWorklistRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalWorklistRecord) {
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

        func list() -> [RegionalWorklistRecord] {
            var out: [RegionalWorklistRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalWorklistRecordStore() -> any RegionalWorklistRecordStore {
        return MemoryRegionalWorklistRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalWorklistRecordStore: RegionalWorklistRecordStore {
        var inner: MemoryRegionalWorklistRecordStore
        var cache: TTLCache<RegionalWorklistRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalWorklistRecordStore, cache: TTLCache<RegionalWorklistRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalWorklistRecord? {
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

        func save(_ item: RegionalWorklistRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalWorklistRecord] {
            return inner.list()
        }
    }

    static func newCachedRegionalWorklistRecordStore(_ inner: MemoryRegionalWorklistRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalWorklistRecordStore {
        return CachedRegionalWorklistRecordStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional worklist records. Empty fields match all.
    final class RegionalWorklistRecordQuery {
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

        func matches(_ item: RegionalWorklistRecord) -> Bool {
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

        func apply(_ items: [RegionalWorklistRecord]) -> [RegionalWorklistRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalWorklistRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalWorklistRecords(_ store: any RegionalWorklistRecordStore, query: RegionalWorklistRecordQuery) -> [RegionalWorklistRecord] {
        return query.apply(store.list())
    }
}
