import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps pending eligibility variances by code.
    protocol PendingEligibilityVarianceStore {
        func find(_ code: String) -> PendingEligibilityVariance?
        func save(_ item: PendingEligibilityVariance)
        func remove(_ code: String) -> Bool
        func list() -> [PendingEligibilityVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingEligibilityVarianceStore: PendingEligibilityVarianceStore {
        var items: [String: PendingEligibilityVariance]
        var order: [String]

        init(items: [String: PendingEligibilityVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingEligibilityVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingEligibilityVariance) {
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

        func list() -> [PendingEligibilityVariance] {
            var out: [PendingEligibilityVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingEligibilityVarianceStore() -> any PendingEligibilityVarianceStore {
        return MemoryPendingEligibilityVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingEligibilityVarianceStore: PendingEligibilityVarianceStore {
        var inner: MemoryPendingEligibilityVarianceStore
        var cache: TTLCache<PendingEligibilityVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingEligibilityVarianceStore, cache: TTLCache<PendingEligibilityVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingEligibilityVariance? {
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

        func save(_ item: PendingEligibilityVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingEligibilityVariance] {
            return inner.list()
        }
    }

    static func newCachedPendingEligibilityVarianceStore(_ inner: MemoryPendingEligibilityVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingEligibilityVarianceStore {
        return CachedPendingEligibilityVarianceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending eligibility variances. Empty fields match all.
    final class PendingEligibilityVarianceQuery {
        var channel: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minAmount: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingEligibilityVariance) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingEligibilityVariance]) -> [PendingEligibilityVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingEligibilityVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingEligibilityVariances(_ store: any PendingEligibilityVarianceStore, query: PendingEligibilityVarianceQuery) -> [PendingEligibilityVariance] {
        return query.apply(store.list())
    }
}
