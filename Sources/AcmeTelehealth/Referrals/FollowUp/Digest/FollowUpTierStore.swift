import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up tiers by code.
    protocol FollowUpTierStore {
        func find(_ code: String) -> FollowUpTier?
        func save(_ item: FollowUpTier)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpTierStore: FollowUpTierStore {
        var items: [String: FollowUpTier]
        var order: [String]

        init(items: [String: FollowUpTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpTier) {
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

        func list() -> [FollowUpTier] {
            var out: [FollowUpTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpTierStore() -> any FollowUpTierStore {
        return MemoryFollowUpTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpTierStore: FollowUpTierStore {
        var inner: MemoryFollowUpTierStore
        var cache: TTLCache<FollowUpTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpTierStore, cache: TTLCache<FollowUpTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpTier? {
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

        func save(_ item: FollowUpTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpTier] {
            return inner.list()
        }
    }

    static func newCachedFollowUpTierStore(_ inner: MemoryFollowUpTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpTierStore {
        return CachedFollowUpTierStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up tiers. Empty fields match all.
    final class FollowUpTierQuery {
        var label: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpTier) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpTier]) -> [FollowUpTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpTiers(_ store: any FollowUpTierStore, query: FollowUpTierQuery) -> [FollowUpTier] {
        return query.apply(store.list())
    }
}
