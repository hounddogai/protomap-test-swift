import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral thresholds by code.
    protocol ReferralThresholdStore {
        func find(_ code: String) -> ReferralThreshold?
        func save(_ item: ReferralThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralThresholdStore: ReferralThresholdStore {
        var items: [String: ReferralThreshold]
        var order: [String]

        init(items: [String: ReferralThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralThreshold) {
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

        func list() -> [ReferralThreshold] {
            var out: [ReferralThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralThresholdStore() -> any ReferralThresholdStore {
        return MemoryReferralThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralThresholdStore: ReferralThresholdStore {
        var inner: MemoryReferralThresholdStore
        var cache: TTLCache<ReferralThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralThresholdStore, cache: TTLCache<ReferralThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralThreshold? {
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

        func save(_ item: ReferralThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralThreshold] {
            return inner.list()
        }
    }

    static func newCachedReferralThresholdStore(_ inner: MemoryReferralThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralThresholdStore {
        return CachedReferralThresholdStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral thresholds. Empty fields match all.
    final class ReferralThresholdQuery {
        var name: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralThreshold) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferralThreshold]) -> [ReferralThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralThresholds(_ store: any ReferralThresholdStore, query: ReferralThresholdQuery) -> [ReferralThreshold] {
        return query.apply(store.list())
    }
}
