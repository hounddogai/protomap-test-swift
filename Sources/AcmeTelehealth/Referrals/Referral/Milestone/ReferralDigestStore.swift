import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral digests by code.
    protocol ReferralDigestStore {
        func find(_ code: String) -> ReferralDigest?
        func save(_ item: ReferralDigest)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralDigestStore: ReferralDigestStore {
        var items: [String: ReferralDigest]
        var order: [String]

        init(items: [String: ReferralDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralDigest) {
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

        func list() -> [ReferralDigest] {
            var out: [ReferralDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralDigestStore() -> any ReferralDigestStore {
        return MemoryReferralDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralDigestStore: ReferralDigestStore {
        var inner: MemoryReferralDigestStore
        var cache: TTLCache<ReferralDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralDigestStore, cache: TTLCache<ReferralDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralDigest? {
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

        func save(_ item: ReferralDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralDigest] {
            return inner.list()
        }
    }

    static func newCachedReferralDigestStore(_ inner: MemoryReferralDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralDigestStore {
        return CachedReferralDigestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral digests. Empty fields match all.
    final class ReferralDigestQuery {
        var label: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralDigest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ReferralDigest]) -> [ReferralDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralDigests(_ store: any ReferralDigestStore, query: ReferralDigestQuery) -> [ReferralDigest] {
        return query.apply(store.list())
    }
}
