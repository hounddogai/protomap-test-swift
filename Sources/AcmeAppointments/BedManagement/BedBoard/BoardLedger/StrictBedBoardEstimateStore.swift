import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps strict bed board estimates by code.
    protocol StrictBedBoardEstimateStore {
        func find(_ code: String) -> StrictBedBoardEstimate?
        func save(_ item: StrictBedBoardEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [StrictBedBoardEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictBedBoardEstimateStore: StrictBedBoardEstimateStore {
        var items: [String: StrictBedBoardEstimate]
        var order: [String]

        init(items: [String: StrictBedBoardEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictBedBoardEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictBedBoardEstimate) {
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

        func list() -> [StrictBedBoardEstimate] {
            var out: [StrictBedBoardEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictBedBoardEstimateStore() -> any StrictBedBoardEstimateStore {
        return MemoryStrictBedBoardEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictBedBoardEstimateStore: StrictBedBoardEstimateStore {
        var inner: MemoryStrictBedBoardEstimateStore
        var cache: TTLCache<StrictBedBoardEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictBedBoardEstimateStore, cache: TTLCache<StrictBedBoardEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictBedBoardEstimate? {
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

        func save(_ item: StrictBedBoardEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictBedBoardEstimate] {
            return inner.list()
        }
    }

    static func newCachedStrictBedBoardEstimateStore(_ inner: MemoryStrictBedBoardEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictBedBoardEstimateStore {
        return CachedStrictBedBoardEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict bed board estimates. Empty fields match all.
    final class StrictBedBoardEstimateQuery {
        var name: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRatio: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictBedBoardEstimate) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictBedBoardEstimate]) -> [StrictBedBoardEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictBedBoardEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictBedBoardEstimates(_ store: any StrictBedBoardEstimateStore, query: StrictBedBoardEstimateQuery) -> [StrictBedBoardEstimate] {
        return query.apply(store.list())
    }
}
