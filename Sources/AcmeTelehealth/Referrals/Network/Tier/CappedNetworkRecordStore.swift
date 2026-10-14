import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps capped network records by code.
    protocol CappedNetworkRecordStore {
        func find(_ code: String) -> CappedNetworkRecord?
        func save(_ item: CappedNetworkRecord)
        func remove(_ code: String) -> Bool
        func list() -> [CappedNetworkRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedNetworkRecordStore: CappedNetworkRecordStore {
        var items: [String: CappedNetworkRecord]
        var order: [String]

        init(items: [String: CappedNetworkRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedNetworkRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedNetworkRecord) {
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

        func list() -> [CappedNetworkRecord] {
            var out: [CappedNetworkRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedNetworkRecordStore() -> any CappedNetworkRecordStore {
        return MemoryCappedNetworkRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedNetworkRecordStore: CappedNetworkRecordStore {
        var inner: MemoryCappedNetworkRecordStore
        var cache: TTLCache<CappedNetworkRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedNetworkRecordStore, cache: TTLCache<CappedNetworkRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedNetworkRecord? {
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

        func save(_ item: CappedNetworkRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedNetworkRecord] {
            return inner.list()
        }
    }

    static func newCachedCappedNetworkRecordStore(_ inner: MemoryCappedNetworkRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedNetworkRecordStore {
        return CachedCappedNetworkRecordStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped network records. Empty fields match all.
    final class CappedNetworkRecordQuery {
        var facility: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedNetworkRecord) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [CappedNetworkRecord]) -> [CappedNetworkRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedNetworkRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedNetworkRecords(_ store: any CappedNetworkRecordStore, query: CappedNetworkRecordQuery) -> [CappedNetworkRecord] {
        return query.apply(store.list())
    }
}
