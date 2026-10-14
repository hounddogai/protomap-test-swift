import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps strict referral preferences by code.
    protocol StrictReferralPreferenceStore {
        func find(_ code: String) -> StrictReferralPreference?
        func save(_ item: StrictReferralPreference)
        func remove(_ code: String) -> Bool
        func list() -> [StrictReferralPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictReferralPreferenceStore: StrictReferralPreferenceStore {
        var items: [String: StrictReferralPreference]
        var order: [String]

        init(items: [String: StrictReferralPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictReferralPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictReferralPreference) {
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

        func list() -> [StrictReferralPreference] {
            var out: [StrictReferralPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictReferralPreferenceStore() -> any StrictReferralPreferenceStore {
        return MemoryStrictReferralPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictReferralPreferenceStore: StrictReferralPreferenceStore {
        var inner: MemoryStrictReferralPreferenceStore
        var cache: TTLCache<StrictReferralPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictReferralPreferenceStore, cache: TTLCache<StrictReferralPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictReferralPreference? {
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

        func save(_ item: StrictReferralPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictReferralPreference] {
            return inner.list()
        }
    }

    static func newCachedStrictReferralPreferenceStore(_ inner: MemoryStrictReferralPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictReferralPreferenceStore {
        return CachedStrictReferralPreferenceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict referral preferences. Empty fields match all.
    final class StrictReferralPreferenceQuery {
        var name: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictReferralPreference) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictReferralPreference]) -> [StrictReferralPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictReferralPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictReferralPreferences(_ store: any StrictReferralPreferenceStore, query: StrictReferralPreferenceQuery) -> [StrictReferralPreference] {
        return query.apply(store.list())
    }
}
