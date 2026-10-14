import AcmePlatform
import Foundation

extension Consent {
    /// Keeps weighted witness records by code.
    protocol WeightedWitnessRecordStore {
        func find(_ code: String) -> WeightedWitnessRecord?
        func save(_ item: WeightedWitnessRecord)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedWitnessRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedWitnessRecordStore: WeightedWitnessRecordStore {
        var items: [String: WeightedWitnessRecord]
        var order: [String]

        init(items: [String: WeightedWitnessRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedWitnessRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedWitnessRecord) {
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

        func list() -> [WeightedWitnessRecord] {
            var out: [WeightedWitnessRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedWitnessRecordStore() -> any WeightedWitnessRecordStore {
        return MemoryWeightedWitnessRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedWitnessRecordStore: WeightedWitnessRecordStore {
        var inner: MemoryWeightedWitnessRecordStore
        var cache: TTLCache<WeightedWitnessRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedWitnessRecordStore, cache: TTLCache<WeightedWitnessRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedWitnessRecord? {
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

        func save(_ item: WeightedWitnessRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedWitnessRecord] {
            return inner.list()
        }
    }

    static func newCachedWeightedWitnessRecordStore(_ inner: MemoryWeightedWitnessRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedWitnessRecordStore {
        return CachedWeightedWitnessRecordStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted witness records. Empty fields match all.
    final class WeightedWitnessRecordQuery {
        var facility: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minCost: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedWitnessRecord) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedWitnessRecord]) -> [WeightedWitnessRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedWitnessRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedWitnessRecords(_ store: any WeightedWitnessRecordStore, query: WeightedWitnessRecordQuery) -> [WeightedWitnessRecord] {
        return query.apply(store.list())
    }
}
