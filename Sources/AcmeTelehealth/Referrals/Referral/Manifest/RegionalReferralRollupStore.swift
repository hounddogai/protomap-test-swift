import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps regional referral rollups by code.
    protocol RegionalReferralRollupStore {
        func find(_ code: String) -> RegionalReferralRollup?
        func save(_ item: RegionalReferralRollup)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalReferralRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalReferralRollupStore: RegionalReferralRollupStore {
        var items: [String: RegionalReferralRollup]
        var order: [String]

        init(items: [String: RegionalReferralRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalReferralRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalReferralRollup) {
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

        func list() -> [RegionalReferralRollup] {
            var out: [RegionalReferralRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalReferralRollupStore() -> any RegionalReferralRollupStore {
        return MemoryRegionalReferralRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalReferralRollupStore: RegionalReferralRollupStore {
        var inner: MemoryRegionalReferralRollupStore
        var cache: TTLCache<RegionalReferralRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalReferralRollupStore, cache: TTLCache<RegionalReferralRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalReferralRollup? {
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

        func save(_ item: RegionalReferralRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalReferralRollup] {
            return inner.list()
        }
    }

    static func newCachedRegionalReferralRollupStore(_ inner: MemoryRegionalReferralRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalReferralRollupStore {
        return CachedRegionalReferralRollupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional referral rollups. Empty fields match all.
    final class RegionalReferralRollupQuery {
        var country: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalReferralRollup) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalReferralRollup]) -> [RegionalReferralRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalReferralRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalReferralRollups(_ store: any RegionalReferralRollupStore, query: RegionalReferralRollupQuery) -> [RegionalReferralRollup] {
        return query.apply(store.list())
    }
}
