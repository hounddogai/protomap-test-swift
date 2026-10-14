import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps weighted eligibility bundles by code.
    protocol WeightedEligibilityBundleStore {
        func find(_ code: String) -> WeightedEligibilityBundle?
        func save(_ item: WeightedEligibilityBundle)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedEligibilityBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedEligibilityBundleStore: WeightedEligibilityBundleStore {
        var items: [String: WeightedEligibilityBundle]
        var order: [String]

        init(items: [String: WeightedEligibilityBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedEligibilityBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedEligibilityBundle) {
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

        func list() -> [WeightedEligibilityBundle] {
            var out: [WeightedEligibilityBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedEligibilityBundleStore() -> any WeightedEligibilityBundleStore {
        return MemoryWeightedEligibilityBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedEligibilityBundleStore: WeightedEligibilityBundleStore {
        var inner: MemoryWeightedEligibilityBundleStore
        var cache: TTLCache<WeightedEligibilityBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedEligibilityBundleStore, cache: TTLCache<WeightedEligibilityBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedEligibilityBundle? {
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

        func save(_ item: WeightedEligibilityBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedEligibilityBundle] {
            return inner.list()
        }
    }

    static func newCachedWeightedEligibilityBundleStore(_ inner: MemoryWeightedEligibilityBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedEligibilityBundleStore {
        return CachedWeightedEligibilityBundleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted eligibility bundles. Empty fields match all.
    final class WeightedEligibilityBundleQuery {
        var country: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedEligibilityBundle) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedEligibilityBundle]) -> [WeightedEligibilityBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedEligibilityBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedEligibilityBundles(_ store: any WeightedEligibilityBundleStore, query: WeightedEligibilityBundleQuery) -> [WeightedEligibilityBundle] {
        return query.apply(store.list())
    }
}
