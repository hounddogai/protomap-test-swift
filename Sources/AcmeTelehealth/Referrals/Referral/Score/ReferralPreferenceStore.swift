import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral preferences by code.
    protocol ReferralPreferenceStore {
        func find(_ code: String) -> ReferralPreference?
        func save(_ item: ReferralPreference)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralPreferenceStore: ReferralPreferenceStore {
        var items: [String: ReferralPreference]
        var order: [String]

        init(items: [String: ReferralPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralPreference) {
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

        func list() -> [ReferralPreference] {
            var out: [ReferralPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralPreferenceStore() -> any ReferralPreferenceStore {
        return MemoryReferralPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralPreferenceStore: ReferralPreferenceStore {
        var inner: MemoryReferralPreferenceStore
        var cache: TTLCache<ReferralPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralPreferenceStore, cache: TTLCache<ReferralPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralPreference? {
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

        func save(_ item: ReferralPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralPreference] {
            return inner.list()
        }
    }

    static func newCachedReferralPreferenceStore(_ inner: MemoryReferralPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralPreferenceStore {
        return CachedReferralPreferenceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral preferences. Empty fields match all.
    final class ReferralPreferenceQuery {
        var facility: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minMargin: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralPreference) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferralPreference]) -> [ReferralPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralPreferences(_ store: any ReferralPreferenceStore, query: ReferralPreferenceQuery) -> [ReferralPreference] {
        return query.apply(store.list())
    }
}
