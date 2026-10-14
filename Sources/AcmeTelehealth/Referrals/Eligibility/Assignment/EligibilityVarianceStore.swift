import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility variances by code.
    protocol EligibilityVarianceStore {
        func find(_ code: String) -> EligibilityVariance?
        func save(_ item: EligibilityVariance)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityVarianceStore: EligibilityVarianceStore {
        var items: [String: EligibilityVariance]
        var order: [String]

        init(items: [String: EligibilityVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityVariance) {
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

        func list() -> [EligibilityVariance] {
            var out: [EligibilityVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityVarianceStore() -> any EligibilityVarianceStore {
        return MemoryEligibilityVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityVarianceStore: EligibilityVarianceStore {
        var inner: MemoryEligibilityVarianceStore
        var cache: TTLCache<EligibilityVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityVarianceStore, cache: TTLCache<EligibilityVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityVariance? {
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

        func save(_ item: EligibilityVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityVariance] {
            return inner.list()
        }
    }

    static func newCachedEligibilityVarianceStore(_ inner: MemoryEligibilityVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityVarianceStore {
        return CachedEligibilityVarianceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility variances. Empty fields match all.
    final class EligibilityVarianceQuery {
        var label: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilityVariance) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [EligibilityVariance]) -> [EligibilityVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityVariances(_ store: any EligibilityVarianceStore, query: EligibilityVarianceQuery) -> [EligibilityVariance] {
        return query.apply(store.list())
    }
}
