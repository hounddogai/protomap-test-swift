import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps strict rounding estimates by code.
    protocol StrictRoundingEstimateStore {
        func find(_ code: String) -> StrictRoundingEstimate?
        func save(_ item: StrictRoundingEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [StrictRoundingEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictRoundingEstimateStore: StrictRoundingEstimateStore {
        var items: [String: StrictRoundingEstimate]
        var order: [String]

        init(items: [String: StrictRoundingEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictRoundingEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictRoundingEstimate) {
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

        func list() -> [StrictRoundingEstimate] {
            var out: [StrictRoundingEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictRoundingEstimateStore() -> any StrictRoundingEstimateStore {
        return MemoryStrictRoundingEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictRoundingEstimateStore: StrictRoundingEstimateStore {
        var inner: MemoryStrictRoundingEstimateStore
        var cache: TTLCache<StrictRoundingEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictRoundingEstimateStore, cache: TTLCache<StrictRoundingEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictRoundingEstimate? {
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

        func save(_ item: StrictRoundingEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictRoundingEstimate] {
            return inner.list()
        }
    }

    static func newCachedStrictRoundingEstimateStore(_ inner: MemoryStrictRoundingEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictRoundingEstimateStore {
        return CachedStrictRoundingEstimateStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict rounding estimates. Empty fields match all.
    final class StrictRoundingEstimateQuery {
        var name: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictRoundingEstimate) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictRoundingEstimate]) -> [StrictRoundingEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictRoundingEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictRoundingEstimates(_ store: any StrictRoundingEstimateStore, query: StrictRoundingEstimateQuery) -> [StrictRoundingEstimate] {
        return query.apply(store.list())
    }
}
