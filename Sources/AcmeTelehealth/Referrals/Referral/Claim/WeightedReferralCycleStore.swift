import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps weighted referral cycles by code.
    protocol WeightedReferralCycleStore {
        func find(_ code: String) -> WeightedReferralCycle?
        func save(_ item: WeightedReferralCycle)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedReferralCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedReferralCycleStore: WeightedReferralCycleStore {
        var items: [String: WeightedReferralCycle]
        var order: [String]

        init(items: [String: WeightedReferralCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedReferralCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedReferralCycle) {
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

        func list() -> [WeightedReferralCycle] {
            var out: [WeightedReferralCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedReferralCycleStore() -> any WeightedReferralCycleStore {
        return MemoryWeightedReferralCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedReferralCycleStore: WeightedReferralCycleStore {
        var inner: MemoryWeightedReferralCycleStore
        var cache: TTLCache<WeightedReferralCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedReferralCycleStore, cache: TTLCache<WeightedReferralCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedReferralCycle? {
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

        func save(_ item: WeightedReferralCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedReferralCycle] {
            return inner.list()
        }
    }

    static func newCachedWeightedReferralCycleStore(_ inner: MemoryWeightedReferralCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedReferralCycleStore {
        return CachedWeightedReferralCycleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted referral cycles. Empty fields match all.
    final class WeightedReferralCycleQuery {
        var unit: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedReferralCycle) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedReferralCycle]) -> [WeightedReferralCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedReferralCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedReferralCycles(_ store: any WeightedReferralCycleStore, query: WeightedReferralCycleQuery) -> [WeightedReferralCycle] {
        return query.apply(store.list())
    }
}
