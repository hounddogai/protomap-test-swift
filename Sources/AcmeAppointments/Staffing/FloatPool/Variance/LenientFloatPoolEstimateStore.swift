import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps lenient float pool estimates by code.
    protocol LenientFloatPoolEstimateStore {
        func find(_ code: String) -> LenientFloatPoolEstimate?
        func save(_ item: LenientFloatPoolEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [LenientFloatPoolEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientFloatPoolEstimateStore: LenientFloatPoolEstimateStore {
        var items: [String: LenientFloatPoolEstimate]
        var order: [String]

        init(items: [String: LenientFloatPoolEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientFloatPoolEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientFloatPoolEstimate) {
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

        func list() -> [LenientFloatPoolEstimate] {
            var out: [LenientFloatPoolEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientFloatPoolEstimateStore() -> any LenientFloatPoolEstimateStore {
        return MemoryLenientFloatPoolEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientFloatPoolEstimateStore: LenientFloatPoolEstimateStore {
        var inner: MemoryLenientFloatPoolEstimateStore
        var cache: TTLCache<LenientFloatPoolEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientFloatPoolEstimateStore, cache: TTLCache<LenientFloatPoolEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientFloatPoolEstimate? {
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

        func save(_ item: LenientFloatPoolEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientFloatPoolEstimate] {
            return inner.list()
        }
    }

    static func newCachedLenientFloatPoolEstimateStore(_ inner: MemoryLenientFloatPoolEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientFloatPoolEstimateStore {
        return CachedLenientFloatPoolEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient float pool estimates. Empty fields match all.
    final class LenientFloatPoolEstimateQuery {
        var title: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCost: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientFloatPoolEstimate) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [LenientFloatPoolEstimate]) -> [LenientFloatPoolEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientFloatPoolEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientFloatPoolEstimates(_ store: any LenientFloatPoolEstimateStore, query: LenientFloatPoolEstimateQuery) -> [LenientFloatPoolEstimate] {
        return query.apply(store.list())
    }
}
