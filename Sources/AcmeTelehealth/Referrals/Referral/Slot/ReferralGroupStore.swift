import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral groups by code.
    protocol ReferralGroupStore {
        func find(_ code: String) -> ReferralGroup?
        func save(_ item: ReferralGroup)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralGroupStore: ReferralGroupStore {
        var items: [String: ReferralGroup]
        var order: [String]

        init(items: [String: ReferralGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralGroup) {
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

        func list() -> [ReferralGroup] {
            var out: [ReferralGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralGroupStore() -> any ReferralGroupStore {
        return MemoryReferralGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralGroupStore: ReferralGroupStore {
        var inner: MemoryReferralGroupStore
        var cache: TTLCache<ReferralGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralGroupStore, cache: TTLCache<ReferralGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralGroup? {
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

        func save(_ item: ReferralGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralGroup] {
            return inner.list()
        }
    }

    static func newCachedReferralGroupStore(_ inner: MemoryReferralGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralGroupStore {
        return CachedReferralGroupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral groups. Empty fields match all.
    final class ReferralGroupQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralGroup) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferralGroup]) -> [ReferralGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralGroups(_ store: any ReferralGroupStore, query: ReferralGroupQuery) -> [ReferralGroup] {
        return query.apply(store.list())
    }
}
