import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps capped charge estimates by code.
    protocol CappedChargeEstimateStore {
        func find(_ code: String) -> CappedChargeEstimate?
        func save(_ item: CappedChargeEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [CappedChargeEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedChargeEstimateStore: CappedChargeEstimateStore {
        var items: [String: CappedChargeEstimate]
        var order: [String]

        init(items: [String: CappedChargeEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedChargeEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedChargeEstimate) {
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

        func list() -> [CappedChargeEstimate] {
            var out: [CappedChargeEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedChargeEstimateStore() -> any CappedChargeEstimateStore {
        return MemoryCappedChargeEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedChargeEstimateStore: CappedChargeEstimateStore {
        var inner: MemoryCappedChargeEstimateStore
        var cache: TTLCache<CappedChargeEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedChargeEstimateStore, cache: TTLCache<CappedChargeEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedChargeEstimate? {
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

        func save(_ item: CappedChargeEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedChargeEstimate] {
            return inner.list()
        }
    }

    static func newCachedCappedChargeEstimateStore(_ inner: MemoryCappedChargeEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedChargeEstimateStore {
        return CachedCappedChargeEstimateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped charge estimates. Empty fields match all.
    final class CappedChargeEstimateQuery {
        var facility: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedChargeEstimate) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedChargeEstimate]) -> [CappedChargeEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedChargeEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedChargeEstimates(_ store: any CappedChargeEstimateStore, query: CappedChargeEstimateQuery) -> [CappedChargeEstimate] {
        return query.apply(store.list())
    }
}
