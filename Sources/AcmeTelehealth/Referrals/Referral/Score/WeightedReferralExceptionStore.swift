import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps weighted referral exceptions by code.
    protocol WeightedReferralExceptionStore {
        func find(_ code: String) -> WeightedReferralException?
        func save(_ item: WeightedReferralException)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedReferralException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedReferralExceptionStore: WeightedReferralExceptionStore {
        var items: [String: WeightedReferralException]
        var order: [String]

        init(items: [String: WeightedReferralException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedReferralException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedReferralException) {
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

        func list() -> [WeightedReferralException] {
            var out: [WeightedReferralException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedReferralExceptionStore() -> any WeightedReferralExceptionStore {
        return MemoryWeightedReferralExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedReferralExceptionStore: WeightedReferralExceptionStore {
        var inner: MemoryWeightedReferralExceptionStore
        var cache: TTLCache<WeightedReferralException>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedReferralExceptionStore, cache: TTLCache<WeightedReferralException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedReferralException? {
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

        func save(_ item: WeightedReferralException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedReferralException] {
            return inner.list()
        }
    }

    static func newCachedWeightedReferralExceptionStore(_ inner: MemoryWeightedReferralExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedReferralExceptionStore {
        return CachedWeightedReferralExceptionStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted referral exceptions. Empty fields match all.
    final class WeightedReferralExceptionQuery {
        var locale: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minRefills: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedReferralException) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedReferralException]) -> [WeightedReferralException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedReferralException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedReferralExceptions(_ store: any WeightedReferralExceptionStore, query: WeightedReferralExceptionQuery) -> [WeightedReferralException] {
        return query.apply(store.list())
    }
}
