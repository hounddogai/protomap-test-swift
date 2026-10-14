import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral metrics by code.
    protocol ReferralMetricStore {
        func find(_ code: String) -> ReferralMetric?
        func save(_ item: ReferralMetric)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralMetricStore: ReferralMetricStore {
        var items: [String: ReferralMetric]
        var order: [String]

        init(items: [String: ReferralMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralMetric) {
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

        func list() -> [ReferralMetric] {
            var out: [ReferralMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralMetricStore() -> any ReferralMetricStore {
        return MemoryReferralMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralMetricStore: ReferralMetricStore {
        var inner: MemoryReferralMetricStore
        var cache: TTLCache<ReferralMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralMetricStore, cache: TTLCache<ReferralMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralMetric? {
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

        func save(_ item: ReferralMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralMetric] {
            return inner.list()
        }
    }

    static func newCachedReferralMetricStore(_ inner: MemoryReferralMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralMetricStore {
        return CachedReferralMetricStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral metrics. Empty fields match all.
    final class ReferralMetricQuery {
        var label: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralMetric) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferralMetric]) -> [ReferralMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralMetrics(_ store: any ReferralMetricStore, query: ReferralMetricQuery) -> [ReferralMetric] {
        return query.apply(store.list())
    }
}
