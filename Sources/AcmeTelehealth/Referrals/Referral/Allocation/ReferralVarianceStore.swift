import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral variances by code.
    protocol ReferralVarianceStore {
        func find(_ code: String) -> ReferralVariance?
        func save(_ item: ReferralVariance)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralVarianceStore: ReferralVarianceStore {
        var items: [String: ReferralVariance]
        var order: [String]

        init(items: [String: ReferralVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralVariance) {
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

        func list() -> [ReferralVariance] {
            var out: [ReferralVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralVarianceStore() -> any ReferralVarianceStore {
        return MemoryReferralVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralVarianceStore: ReferralVarianceStore {
        var inner: MemoryReferralVarianceStore
        var cache: TTLCache<ReferralVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralVarianceStore, cache: TTLCache<ReferralVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralVariance? {
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

        func save(_ item: ReferralVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralVariance] {
            return inner.list()
        }
    }

    static func newCachedReferralVarianceStore(_ inner: MemoryReferralVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralVarianceStore {
        return CachedReferralVarianceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral variances. Empty fields match all.
    final class ReferralVarianceQuery {
        var channel: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCopay: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralVariance) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferralVariance]) -> [ReferralVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralVariances(_ store: any ReferralVarianceStore, query: ReferralVarianceQuery) -> [ReferralVariance] {
        return query.apply(store.list())
    }
}
