import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps fallback bed board variances by code.
    protocol FallbackBedBoardVarianceStore {
        func find(_ code: String) -> FallbackBedBoardVariance?
        func save(_ item: FallbackBedBoardVariance)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackBedBoardVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackBedBoardVarianceStore: FallbackBedBoardVarianceStore {
        var items: [String: FallbackBedBoardVariance]
        var order: [String]

        init(items: [String: FallbackBedBoardVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackBedBoardVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackBedBoardVariance) {
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

        func list() -> [FallbackBedBoardVariance] {
            var out: [FallbackBedBoardVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackBedBoardVarianceStore() -> any FallbackBedBoardVarianceStore {
        return MemoryFallbackBedBoardVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackBedBoardVarianceStore: FallbackBedBoardVarianceStore {
        var inner: MemoryFallbackBedBoardVarianceStore
        var cache: TTLCache<FallbackBedBoardVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackBedBoardVarianceStore, cache: TTLCache<FallbackBedBoardVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackBedBoardVariance? {
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

        func save(_ item: FallbackBedBoardVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackBedBoardVariance] {
            return inner.list()
        }
    }

    static func newCachedFallbackBedBoardVarianceStore(_ inner: MemoryFallbackBedBoardVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackBedBoardVarianceStore {
        return CachedFallbackBedBoardVarianceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback bed board variances. Empty fields match all.
    final class FallbackBedBoardVarianceQuery {
        var segment: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minAmount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackBedBoardVariance) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [FallbackBedBoardVariance]) -> [FallbackBedBoardVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackBedBoardVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackBedBoardVariances(_ store: any FallbackBedBoardVarianceStore, query: FallbackBedBoardVarianceQuery) -> [FallbackBedBoardVariance] {
        return query.apply(store.list())
    }
}
