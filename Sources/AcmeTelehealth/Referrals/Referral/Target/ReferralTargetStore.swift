import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral targets by code.
    protocol ReferralTargetStore {
        func find(_ code: String) -> ReferralTarget?
        func save(_ item: ReferralTarget)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralTargetStore: ReferralTargetStore {
        var items: [String: ReferralTarget]
        var order: [String]

        init(items: [String: ReferralTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralTarget) {
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

        func list() -> [ReferralTarget] {
            var out: [ReferralTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralTargetStore() -> any ReferralTargetStore {
        return MemoryReferralTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralTargetStore: ReferralTargetStore {
        var inner: MemoryReferralTargetStore
        var cache: TTLCache<ReferralTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralTargetStore, cache: TTLCache<ReferralTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralTarget? {
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

        func save(_ item: ReferralTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralTarget] {
            return inner.list()
        }
    }

    static func newCachedReferralTargetStore(_ inner: MemoryReferralTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralTargetStore {
        return CachedReferralTargetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral targets. Empty fields match all.
    final class ReferralTargetQuery {
        var name: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralTarget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferralTarget]) -> [ReferralTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralTargets(_ store: any ReferralTargetStore, query: ReferralTargetQuery) -> [ReferralTarget] {
        return query.apply(store.list())
    }
}
