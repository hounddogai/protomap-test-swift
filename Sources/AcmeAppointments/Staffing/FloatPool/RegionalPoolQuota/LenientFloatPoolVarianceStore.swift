import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps lenient float pool variances by code.
    protocol LenientFloatPoolVarianceStore {
        func find(_ code: String) -> LenientFloatPoolVariance?
        func save(_ item: LenientFloatPoolVariance)
        func remove(_ code: String) -> Bool
        func list() -> [LenientFloatPoolVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientFloatPoolVarianceStore: LenientFloatPoolVarianceStore {
        var items: [String: LenientFloatPoolVariance]
        var order: [String]

        init(items: [String: LenientFloatPoolVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientFloatPoolVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientFloatPoolVariance) {
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

        func list() -> [LenientFloatPoolVariance] {
            var out: [LenientFloatPoolVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientFloatPoolVarianceStore() -> any LenientFloatPoolVarianceStore {
        return MemoryLenientFloatPoolVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientFloatPoolVarianceStore: LenientFloatPoolVarianceStore {
        var inner: MemoryLenientFloatPoolVarianceStore
        var cache: TTLCache<LenientFloatPoolVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientFloatPoolVarianceStore, cache: TTLCache<LenientFloatPoolVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientFloatPoolVariance? {
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

        func save(_ item: LenientFloatPoolVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientFloatPoolVariance] {
            return inner.list()
        }
    }

    static func newCachedLenientFloatPoolVarianceStore(_ inner: MemoryLenientFloatPoolVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientFloatPoolVarianceStore {
        return CachedLenientFloatPoolVarianceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient float pool variances. Empty fields match all.
    final class LenientFloatPoolVarianceQuery {
        var facility: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minBudget: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientFloatPoolVariance) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientFloatPoolVariance]) -> [LenientFloatPoolVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientFloatPoolVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientFloatPoolVariances(_ store: any LenientFloatPoolVarianceStore, query: LenientFloatPoolVarianceQuery) -> [LenientFloatPoolVariance] {
        return query.apply(store.list())
    }
}
