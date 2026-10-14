import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps lenient eligibility estimates by code.
    protocol LenientEligibilityEstimateStore {
        func find(_ code: String) -> LenientEligibilityEstimate?
        func save(_ item: LenientEligibilityEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [LenientEligibilityEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientEligibilityEstimateStore: LenientEligibilityEstimateStore {
        var items: [String: LenientEligibilityEstimate]
        var order: [String]

        init(items: [String: LenientEligibilityEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientEligibilityEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientEligibilityEstimate) {
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

        func list() -> [LenientEligibilityEstimate] {
            var out: [LenientEligibilityEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientEligibilityEstimateStore() -> any LenientEligibilityEstimateStore {
        return MemoryLenientEligibilityEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientEligibilityEstimateStore: LenientEligibilityEstimateStore {
        var inner: MemoryLenientEligibilityEstimateStore
        var cache: TTLCache<LenientEligibilityEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientEligibilityEstimateStore, cache: TTLCache<LenientEligibilityEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientEligibilityEstimate? {
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

        func save(_ item: LenientEligibilityEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientEligibilityEstimate] {
            return inner.list()
        }
    }

    static func newCachedLenientEligibilityEstimateStore(_ inner: MemoryLenientEligibilityEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientEligibilityEstimateStore {
        return CachedLenientEligibilityEstimateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient eligibility estimates. Empty fields match all.
    final class LenientEligibilityEstimateQuery {
        var ward: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientEligibilityEstimate) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientEligibilityEstimate]) -> [LenientEligibilityEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientEligibilityEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientEligibilityEstimates(_ store: any LenientEligibilityEstimateStore, query: LenientEligibilityEstimateQuery) -> [LenientEligibilityEstimate] {
        return query.apply(store.list())
    }
}
