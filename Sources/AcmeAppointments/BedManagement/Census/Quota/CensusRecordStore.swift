import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps census records by code.
    protocol CensusRecordStore {
        func find(_ code: String) -> CensusRecord?
        func save(_ item: CensusRecord)
        func remove(_ code: String) -> Bool
        func list() -> [CensusRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCensusRecordStore: CensusRecordStore {
        var items: [String: CensusRecord]
        var order: [String]

        init(items: [String: CensusRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CensusRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CensusRecord) {
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

        func list() -> [CensusRecord] {
            var out: [CensusRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCensusRecordStore() -> any CensusRecordStore {
        return MemoryCensusRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCensusRecordStore: CensusRecordStore {
        var inner: MemoryCensusRecordStore
        var cache: TTLCache<CensusRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryCensusRecordStore, cache: TTLCache<CensusRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CensusRecord? {
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

        func save(_ item: CensusRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CensusRecord] {
            return inner.list()
        }
    }

    static func newCachedCensusRecordStore(_ inner: MemoryCensusRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CensusRecordStore {
        return CachedCensusRecordStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects census records. Empty fields match all.
    final class CensusRecordQuery {
        var label: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRate: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CensusRecord) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CensusRecord]) -> [CensusRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CensusRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCensusRecords(_ store: any CensusRecordStore, query: CensusRecordQuery) -> [CensusRecord] {
        return query.apply(store.list())
    }
}
