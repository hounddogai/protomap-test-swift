import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps primary referral exceptions by code.
    protocol PrimaryReferralExceptionStore {
        func find(_ code: String) -> PrimaryReferralException?
        func save(_ item: PrimaryReferralException)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryReferralException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryReferralExceptionStore: PrimaryReferralExceptionStore {
        var items: [String: PrimaryReferralException]
        var order: [String]

        init(items: [String: PrimaryReferralException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryReferralException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryReferralException) {
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

        func list() -> [PrimaryReferralException] {
            var out: [PrimaryReferralException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryReferralExceptionStore() -> any PrimaryReferralExceptionStore {
        return MemoryPrimaryReferralExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryReferralExceptionStore: PrimaryReferralExceptionStore {
        var inner: MemoryPrimaryReferralExceptionStore
        var cache: TTLCache<PrimaryReferralException>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryReferralExceptionStore, cache: TTLCache<PrimaryReferralException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryReferralException? {
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

        func save(_ item: PrimaryReferralException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryReferralException] {
            return inner.list()
        }
    }

    static func newCachedPrimaryReferralExceptionStore(_ inner: MemoryPrimaryReferralExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryReferralExceptionStore {
        return CachedPrimaryReferralExceptionStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary referral exceptions. Empty fields match all.
    final class PrimaryReferralExceptionQuery {
        var category: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryReferralException) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [PrimaryReferralException]) -> [PrimaryReferralException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryReferralException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryReferralExceptions(_ store: any PrimaryReferralExceptionStore, query: PrimaryReferralExceptionQuery) -> [PrimaryReferralException] {
        return query.apply(store.list())
    }
}
