import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps capped referral rollups by code.
    protocol CappedReferralRollupStore {
        func find(_ code: String) -> CappedReferralRollup?
        func save(_ item: CappedReferralRollup)
        func remove(_ code: String) -> Bool
        func list() -> [CappedReferralRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedReferralRollupStore: CappedReferralRollupStore {
        var items: [String: CappedReferralRollup]
        var order: [String]

        init(items: [String: CappedReferralRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedReferralRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedReferralRollup) {
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

        func list() -> [CappedReferralRollup] {
            var out: [CappedReferralRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedReferralRollupStore() -> any CappedReferralRollupStore {
        return MemoryCappedReferralRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedReferralRollupStore: CappedReferralRollupStore {
        var inner: MemoryCappedReferralRollupStore
        var cache: TTLCache<CappedReferralRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedReferralRollupStore, cache: TTLCache<CappedReferralRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedReferralRollup? {
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

        func save(_ item: CappedReferralRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedReferralRollup] {
            return inner.list()
        }
    }

    static func newCachedCappedReferralRollupStore(_ inner: MemoryCappedReferralRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedReferralRollupStore {
        return CachedCappedReferralRollupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped referral rollups. Empty fields match all.
    final class CappedReferralRollupQuery {
        var locale: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedReferralRollup) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedReferralRollup]) -> [CappedReferralRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedReferralRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedReferralRollups(_ store: any CappedReferralRollupStore, query: CappedReferralRollupQuery) -> [CappedReferralRollup] {
        return query.apply(store.list())
    }
}
