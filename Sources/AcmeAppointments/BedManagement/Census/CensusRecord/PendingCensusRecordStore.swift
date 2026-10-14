import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps pending census records by code.
    protocol PendingCensusRecordStore {
        func find(_ code: String) -> PendingCensusRecord?
        func save(_ item: PendingCensusRecord)
        func remove(_ code: String) -> Bool
        func list() -> [PendingCensusRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingCensusRecordStore: PendingCensusRecordStore {
        var items: [String: PendingCensusRecord]
        var order: [String]

        init(items: [String: PendingCensusRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingCensusRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingCensusRecord) {
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

        func list() -> [PendingCensusRecord] {
            var out: [PendingCensusRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingCensusRecordStore() -> any PendingCensusRecordStore {
        return MemoryPendingCensusRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingCensusRecordStore: PendingCensusRecordStore {
        var inner: MemoryPendingCensusRecordStore
        var cache: TTLCache<PendingCensusRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingCensusRecordStore, cache: TTLCache<PendingCensusRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingCensusRecord? {
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

        func save(_ item: PendingCensusRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingCensusRecord] {
            return inner.list()
        }
    }

    static func newCachedPendingCensusRecordStore(_ inner: MemoryPendingCensusRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingCensusRecordStore {
        return CachedPendingCensusRecordStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending census records. Empty fields match all.
    final class PendingCensusRecordQuery {
        var country: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingCensusRecord) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingCensusRecord]) -> [PendingCensusRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingCensusRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingCensusRecords(_ store: any PendingCensusRecordStore, query: PendingCensusRecordQuery) -> [PendingCensusRecord] {
        return query.apply(store.list())
    }
}
