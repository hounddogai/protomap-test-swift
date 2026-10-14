import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps rolling eligibility variances by code.
    protocol RollingEligibilityVarianceStore {
        func find(_ code: String) -> RollingEligibilityVariance?
        func save(_ item: RollingEligibilityVariance)
        func remove(_ code: String) -> Bool
        func list() -> [RollingEligibilityVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingEligibilityVarianceStore: RollingEligibilityVarianceStore {
        var items: [String: RollingEligibilityVariance]
        var order: [String]

        init(items: [String: RollingEligibilityVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingEligibilityVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingEligibilityVariance) {
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

        func list() -> [RollingEligibilityVariance] {
            var out: [RollingEligibilityVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingEligibilityVarianceStore() -> any RollingEligibilityVarianceStore {
        return MemoryRollingEligibilityVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingEligibilityVarianceStore: RollingEligibilityVarianceStore {
        var inner: MemoryRollingEligibilityVarianceStore
        var cache: TTLCache<RollingEligibilityVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingEligibilityVarianceStore, cache: TTLCache<RollingEligibilityVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingEligibilityVariance? {
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

        func save(_ item: RollingEligibilityVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingEligibilityVariance] {
            return inner.list()
        }
    }

    static func newCachedRollingEligibilityVarianceStore(_ inner: MemoryRollingEligibilityVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingEligibilityVarianceStore {
        return CachedRollingEligibilityVarianceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling eligibility variances. Empty fields match all.
    final class RollingEligibilityVarianceQuery {
        var title: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingEligibilityVariance) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [RollingEligibilityVariance]) -> [RollingEligibilityVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingEligibilityVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingEligibilityVariances(_ store: any RollingEligibilityVarianceStore, query: RollingEligibilityVarianceQuery) -> [RollingEligibilityVariance] {
        return query.apply(store.list())
    }
}
