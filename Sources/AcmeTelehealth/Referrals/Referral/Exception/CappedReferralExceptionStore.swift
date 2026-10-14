import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps capped referral exceptions by code.
    protocol CappedReferralExceptionStore {
        func find(_ code: String) -> CappedReferralException?
        func save(_ item: CappedReferralException)
        func remove(_ code: String) -> Bool
        func list() -> [CappedReferralException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedReferralExceptionStore: CappedReferralExceptionStore {
        var items: [String: CappedReferralException]
        var order: [String]

        init(items: [String: CappedReferralException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedReferralException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedReferralException) {
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

        func list() -> [CappedReferralException] {
            var out: [CappedReferralException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedReferralExceptionStore() -> any CappedReferralExceptionStore {
        return MemoryCappedReferralExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedReferralExceptionStore: CappedReferralExceptionStore {
        var inner: MemoryCappedReferralExceptionStore
        var cache: TTLCache<CappedReferralException>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedReferralExceptionStore, cache: TTLCache<CappedReferralException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedReferralException? {
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

        func save(_ item: CappedReferralException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedReferralException] {
            return inner.list()
        }
    }

    static func newCachedCappedReferralExceptionStore(_ inner: MemoryCappedReferralExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedReferralExceptionStore {
        return CachedCappedReferralExceptionStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped referral exceptions. Empty fields match all.
    final class CappedReferralExceptionQuery {
        var name: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedReferralException) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedReferralException]) -> [CappedReferralException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedReferralException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedReferralExceptions(_ store: any CappedReferralExceptionStore, query: CappedReferralExceptionQuery) -> [CappedReferralException] {
        return query.apply(store.list())
    }
}
