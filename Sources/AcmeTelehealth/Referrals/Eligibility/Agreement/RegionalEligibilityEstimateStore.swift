import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps regional eligibility estimates by code.
    protocol RegionalEligibilityEstimateStore {
        func find(_ code: String) -> RegionalEligibilityEstimate?
        func save(_ item: RegionalEligibilityEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalEligibilityEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalEligibilityEstimateStore: RegionalEligibilityEstimateStore {
        var items: [String: RegionalEligibilityEstimate]
        var order: [String]

        init(items: [String: RegionalEligibilityEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalEligibilityEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalEligibilityEstimate) {
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

        func list() -> [RegionalEligibilityEstimate] {
            var out: [RegionalEligibilityEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalEligibilityEstimateStore() -> any RegionalEligibilityEstimateStore {
        return MemoryRegionalEligibilityEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalEligibilityEstimateStore: RegionalEligibilityEstimateStore {
        var inner: MemoryRegionalEligibilityEstimateStore
        var cache: TTLCache<RegionalEligibilityEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalEligibilityEstimateStore, cache: TTLCache<RegionalEligibilityEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalEligibilityEstimate? {
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

        func save(_ item: RegionalEligibilityEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalEligibilityEstimate] {
            return inner.list()
        }
    }

    static func newCachedRegionalEligibilityEstimateStore(_ inner: MemoryRegionalEligibilityEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalEligibilityEstimateStore {
        return CachedRegionalEligibilityEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional eligibility estimates. Empty fields match all.
    final class RegionalEligibilityEstimateQuery {
        var title: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalEligibilityEstimate) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalEligibilityEstimate]) -> [RegionalEligibilityEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalEligibilityEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalEligibilityEstimates(_ store: any RegionalEligibilityEstimateStore, query: RegionalEligibilityEstimateQuery) -> [RegionalEligibilityEstimate] {
        return query.apply(store.list())
    }
}
