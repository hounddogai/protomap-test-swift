import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps tiered referral exceptions by code.
    protocol TieredReferralExceptionStore {
        func find(_ code: String) -> TieredReferralException?
        func save(_ item: TieredReferralException)
        func remove(_ code: String) -> Bool
        func list() -> [TieredReferralException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredReferralExceptionStore: TieredReferralExceptionStore {
        var items: [String: TieredReferralException]
        var order: [String]

        init(items: [String: TieredReferralException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredReferralException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredReferralException) {
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

        func list() -> [TieredReferralException] {
            var out: [TieredReferralException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredReferralExceptionStore() -> any TieredReferralExceptionStore {
        return MemoryTieredReferralExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredReferralExceptionStore: TieredReferralExceptionStore {
        var inner: MemoryTieredReferralExceptionStore
        var cache: TTLCache<TieredReferralException>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredReferralExceptionStore, cache: TTLCache<TieredReferralException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredReferralException? {
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

        func save(_ item: TieredReferralException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredReferralException] {
            return inner.list()
        }
    }

    static func newCachedTieredReferralExceptionStore(_ inner: MemoryTieredReferralExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredReferralExceptionStore {
        return CachedTieredReferralExceptionStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered referral exceptions. Empty fields match all.
    final class TieredReferralExceptionQuery {
        var title: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredReferralException) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredReferralException]) -> [TieredReferralException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredReferralException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredReferralExceptions(_ store: any TieredReferralExceptionStore, query: TieredReferralExceptionQuery) -> [TieredReferralException] {
        return query.apply(store.list())
    }
}
