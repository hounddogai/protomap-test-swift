import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral baselines by code.
    protocol ReferralBaselineStore {
        func find(_ code: String) -> ReferralBaseline?
        func save(_ item: ReferralBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralBaselineStore: ReferralBaselineStore {
        var items: [String: ReferralBaseline]
        var order: [String]

        init(items: [String: ReferralBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralBaseline) {
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

        func list() -> [ReferralBaseline] {
            var out: [ReferralBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralBaselineStore() -> any ReferralBaselineStore {
        return MemoryReferralBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralBaselineStore: ReferralBaselineStore {
        var inner: MemoryReferralBaselineStore
        var cache: TTLCache<ReferralBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralBaselineStore, cache: TTLCache<ReferralBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralBaseline? {
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

        func save(_ item: ReferralBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralBaseline] {
            return inner.list()
        }
    }

    static func newCachedReferralBaselineStore(_ inner: MemoryReferralBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralBaselineStore {
        return CachedReferralBaselineStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral baselines. Empty fields match all.
    final class ReferralBaselineQuery {
        var label: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRate: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralBaseline) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferralBaseline]) -> [ReferralBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralBaselines(_ store: any ReferralBaselineStore, query: ReferralBaselineQuery) -> [ReferralBaseline] {
        return query.apply(store.list())
    }
}
