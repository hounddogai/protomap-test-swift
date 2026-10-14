import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps seasonal referral profiles by code.
    protocol SeasonalReferralProfileStore {
        func find(_ code: String) -> SeasonalReferralProfile?
        func save(_ item: SeasonalReferralProfile)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalReferralProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalReferralProfileStore: SeasonalReferralProfileStore {
        var items: [String: SeasonalReferralProfile]
        var order: [String]

        init(items: [String: SeasonalReferralProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalReferralProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalReferralProfile) {
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

        func list() -> [SeasonalReferralProfile] {
            var out: [SeasonalReferralProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalReferralProfileStore() -> any SeasonalReferralProfileStore {
        return MemorySeasonalReferralProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalReferralProfileStore: SeasonalReferralProfileStore {
        var inner: MemorySeasonalReferralProfileStore
        var cache: TTLCache<SeasonalReferralProfile>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalReferralProfileStore, cache: TTLCache<SeasonalReferralProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalReferralProfile? {
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

        func save(_ item: SeasonalReferralProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalReferralProfile] {
            return inner.list()
        }
    }

    static func newCachedSeasonalReferralProfileStore(_ inner: MemorySeasonalReferralProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalReferralProfileStore {
        return CachedSeasonalReferralProfileStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal referral profiles. Empty fields match all.
    final class SeasonalReferralProfileQuery {
        var ward: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minWeight: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalReferralProfile) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [SeasonalReferralProfile]) -> [SeasonalReferralProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalReferralProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalReferralProfiles(_ store: any SeasonalReferralProfileStore, query: SeasonalReferralProfileQuery) -> [SeasonalReferralProfile] {
        return query.apply(store.list())
    }
}
