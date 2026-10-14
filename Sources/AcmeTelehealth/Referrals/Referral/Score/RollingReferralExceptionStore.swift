import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps rolling referral exceptions by code.
    protocol RollingReferralExceptionStore {
        func find(_ code: String) -> RollingReferralException?
        func save(_ item: RollingReferralException)
        func remove(_ code: String) -> Bool
        func list() -> [RollingReferralException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingReferralExceptionStore: RollingReferralExceptionStore {
        var items: [String: RollingReferralException]
        var order: [String]

        init(items: [String: RollingReferralException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingReferralException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingReferralException) {
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

        func list() -> [RollingReferralException] {
            var out: [RollingReferralException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingReferralExceptionStore() -> any RollingReferralExceptionStore {
        return MemoryRollingReferralExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingReferralExceptionStore: RollingReferralExceptionStore {
        var inner: MemoryRollingReferralExceptionStore
        var cache: TTLCache<RollingReferralException>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingReferralExceptionStore, cache: TTLCache<RollingReferralException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingReferralException? {
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

        func save(_ item: RollingReferralException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingReferralException] {
            return inner.list()
        }
    }

    static func newCachedRollingReferralExceptionStore(_ inner: MemoryRollingReferralExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingReferralExceptionStore {
        return CachedRollingReferralExceptionStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling referral exceptions. Empty fields match all.
    final class RollingReferralExceptionQuery {
        var label: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minLimit: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingReferralException) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingReferralException]) -> [RollingReferralException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingReferralException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingReferralExceptions(_ store: any RollingReferralExceptionStore, query: RollingReferralExceptionQuery) -> [RollingReferralException] {
        return query.apply(store.list())
    }
}
