import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps lenient cleaning estimates by code.
    protocol LenientCleaningEstimateStore {
        func find(_ code: String) -> LenientCleaningEstimate?
        func save(_ item: LenientCleaningEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [LenientCleaningEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientCleaningEstimateStore: LenientCleaningEstimateStore {
        var items: [String: LenientCleaningEstimate]
        var order: [String]

        init(items: [String: LenientCleaningEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientCleaningEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientCleaningEstimate) {
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

        func list() -> [LenientCleaningEstimate] {
            var out: [LenientCleaningEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientCleaningEstimateStore() -> any LenientCleaningEstimateStore {
        return MemoryLenientCleaningEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientCleaningEstimateStore: LenientCleaningEstimateStore {
        var inner: MemoryLenientCleaningEstimateStore
        var cache: TTLCache<LenientCleaningEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientCleaningEstimateStore, cache: TTLCache<LenientCleaningEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientCleaningEstimate? {
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

        func save(_ item: LenientCleaningEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientCleaningEstimate] {
            return inner.list()
        }
    }

    static func newCachedLenientCleaningEstimateStore(_ inner: MemoryLenientCleaningEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientCleaningEstimateStore {
        return CachedLenientCleaningEstimateStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient cleaning estimates. Empty fields match all.
    final class LenientCleaningEstimateQuery {
        var name: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minBudget: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientCleaningEstimate) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [LenientCleaningEstimate]) -> [LenientCleaningEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientCleaningEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientCleaningEstimates(_ store: any LenientCleaningEstimateStore, query: LenientCleaningEstimateQuery) -> [LenientCleaningEstimate] {
        return query.apply(store.list())
    }
}
