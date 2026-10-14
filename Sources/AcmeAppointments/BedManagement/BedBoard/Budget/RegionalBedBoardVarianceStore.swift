import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps regional bed board variances by code.
    protocol RegionalBedBoardVarianceStore {
        func find(_ code: String) -> RegionalBedBoardVariance?
        func save(_ item: RegionalBedBoardVariance)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalBedBoardVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalBedBoardVarianceStore: RegionalBedBoardVarianceStore {
        var items: [String: RegionalBedBoardVariance]
        var order: [String]

        init(items: [String: RegionalBedBoardVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalBedBoardVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalBedBoardVariance) {
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

        func list() -> [RegionalBedBoardVariance] {
            var out: [RegionalBedBoardVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalBedBoardVarianceStore() -> any RegionalBedBoardVarianceStore {
        return MemoryRegionalBedBoardVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalBedBoardVarianceStore: RegionalBedBoardVarianceStore {
        var inner: MemoryRegionalBedBoardVarianceStore
        var cache: TTLCache<RegionalBedBoardVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalBedBoardVarianceStore, cache: TTLCache<RegionalBedBoardVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalBedBoardVariance? {
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

        func save(_ item: RegionalBedBoardVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalBedBoardVariance] {
            return inner.list()
        }
    }

    static func newCachedRegionalBedBoardVarianceStore(_ inner: MemoryRegionalBedBoardVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalBedBoardVarianceStore {
        return CachedRegionalBedBoardVarianceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional bed board variances. Empty fields match all.
    final class RegionalBedBoardVarianceQuery {
        var unit: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalBedBoardVariance) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalBedBoardVariance]) -> [RegionalBedBoardVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalBedBoardVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalBedBoardVariances(_ store: any RegionalBedBoardVarianceStore, query: RegionalBedBoardVarianceQuery) -> [RegionalBedBoardVariance] {
        return query.apply(store.list())
    }
}
