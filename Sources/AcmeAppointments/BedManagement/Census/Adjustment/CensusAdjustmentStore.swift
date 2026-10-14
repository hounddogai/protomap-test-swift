import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps census adjustments by code.
    protocol CensusAdjustmentStore {
        func find(_ code: String) -> CensusAdjustment?
        func save(_ item: CensusAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [CensusAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCensusAdjustmentStore: CensusAdjustmentStore {
        var items: [String: CensusAdjustment]
        var order: [String]

        init(items: [String: CensusAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CensusAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CensusAdjustment) {
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

        func list() -> [CensusAdjustment] {
            var out: [CensusAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCensusAdjustmentStore() -> any CensusAdjustmentStore {
        return MemoryCensusAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCensusAdjustmentStore: CensusAdjustmentStore {
        var inner: MemoryCensusAdjustmentStore
        var cache: TTLCache<CensusAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryCensusAdjustmentStore, cache: TTLCache<CensusAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CensusAdjustment? {
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

        func save(_ item: CensusAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CensusAdjustment] {
            return inner.list()
        }
    }

    static func newCachedCensusAdjustmentStore(_ inner: MemoryCensusAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CensusAdjustmentStore {
        return CachedCensusAdjustmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects census adjustments. Empty fields match all.
    final class CensusAdjustmentQuery {
        var ward: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CensusAdjustment) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CensusAdjustment]) -> [CensusAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CensusAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCensusAdjustments(_ store: any CensusAdjustmentStore, query: CensusAdjustmentQuery) -> [CensusAdjustment] {
        return query.apply(store.list())
    }
}
