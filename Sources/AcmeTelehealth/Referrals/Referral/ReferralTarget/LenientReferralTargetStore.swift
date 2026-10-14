import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps lenient referral targets by code.
    protocol LenientReferralTargetStore {
        func find(_ code: String) -> LenientReferralTarget?
        func save(_ item: LenientReferralTarget)
        func remove(_ code: String) -> Bool
        func list() -> [LenientReferralTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientReferralTargetStore: LenientReferralTargetStore {
        var items: [String: LenientReferralTarget]
        var order: [String]

        init(items: [String: LenientReferralTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientReferralTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientReferralTarget) {
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

        func list() -> [LenientReferralTarget] {
            var out: [LenientReferralTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientReferralTargetStore() -> any LenientReferralTargetStore {
        return MemoryLenientReferralTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientReferralTargetStore: LenientReferralTargetStore {
        var inner: MemoryLenientReferralTargetStore
        var cache: TTLCache<LenientReferralTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientReferralTargetStore, cache: TTLCache<LenientReferralTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientReferralTarget? {
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

        func save(_ item: LenientReferralTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientReferralTarget] {
            return inner.list()
        }
    }

    static func newCachedLenientReferralTargetStore(_ inner: MemoryLenientReferralTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientReferralTargetStore {
        return CachedLenientReferralTargetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient referral targets. Empty fields match all.
    final class LenientReferralTargetQuery {
        var facility: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minWeight: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientReferralTarget) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientReferralTarget]) -> [LenientReferralTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientReferralTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientReferralTargets(_ store: any LenientReferralTargetStore, query: LenientReferralTargetQuery) -> [LenientReferralTarget] {
        return query.apply(store.list())
    }
}
