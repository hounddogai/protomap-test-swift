import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board metrics by code.
    protocol BedBoardMetricStore {
        func find(_ code: String) -> BedBoardMetric?
        func save(_ item: BedBoardMetric)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardMetricStore: BedBoardMetricStore {
        var items: [String: BedBoardMetric]
        var order: [String]

        init(items: [String: BedBoardMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardMetric) {
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

        func list() -> [BedBoardMetric] {
            var out: [BedBoardMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardMetricStore() -> any BedBoardMetricStore {
        return MemoryBedBoardMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardMetricStore: BedBoardMetricStore {
        var inner: MemoryBedBoardMetricStore
        var cache: TTLCache<BedBoardMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardMetricStore, cache: TTLCache<BedBoardMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardMetric? {
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

        func save(_ item: BedBoardMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardMetric] {
            return inner.list()
        }
    }

    static func newCachedBedBoardMetricStore(_ inner: MemoryBedBoardMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardMetricStore {
        return CachedBedBoardMetricStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board metrics. Empty fields match all.
    final class BedBoardMetricQuery {
        var name: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minAmount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardMetric) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BedBoardMetric]) -> [BedBoardMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardMetrics(_ store: any BedBoardMetricStore, query: BedBoardMetricQuery) -> [BedBoardMetric] {
        return query.apply(store.list())
    }
}
