import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps tiered discharge plan records by code.
    protocol TieredDischargePlanRecordStore {
        func find(_ code: String) -> TieredDischargePlanRecord?
        func save(_ item: TieredDischargePlanRecord)
        func remove(_ code: String) -> Bool
        func list() -> [TieredDischargePlanRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredDischargePlanRecordStore: TieredDischargePlanRecordStore {
        var items: [String: TieredDischargePlanRecord]
        var order: [String]

        init(items: [String: TieredDischargePlanRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredDischargePlanRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredDischargePlanRecord) {
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

        func list() -> [TieredDischargePlanRecord] {
            var out: [TieredDischargePlanRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredDischargePlanRecordStore() -> any TieredDischargePlanRecordStore {
        return MemoryTieredDischargePlanRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredDischargePlanRecordStore: TieredDischargePlanRecordStore {
        var inner: MemoryTieredDischargePlanRecordStore
        var cache: TTLCache<TieredDischargePlanRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredDischargePlanRecordStore, cache: TTLCache<TieredDischargePlanRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredDischargePlanRecord? {
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

        func save(_ item: TieredDischargePlanRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredDischargePlanRecord] {
            return inner.list()
        }
    }

    static func newCachedTieredDischargePlanRecordStore(_ inner: MemoryTieredDischargePlanRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredDischargePlanRecordStore {
        return CachedTieredDischargePlanRecordStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered discharge plan records. Empty fields match all.
    final class TieredDischargePlanRecordQuery {
        var facility: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minWeight: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredDischargePlanRecord) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredDischargePlanRecord]) -> [TieredDischargePlanRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredDischargePlanRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredDischargePlanRecords(_ store: any TieredDischargePlanRecordStore, query: TieredDischargePlanRecordQuery) -> [TieredDischargePlanRecord] {
        return query.apply(store.list())
    }
}
