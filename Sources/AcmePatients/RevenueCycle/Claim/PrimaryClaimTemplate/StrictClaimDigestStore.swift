import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps strict claim digests by code.
    protocol StrictClaimDigestStore {
        func find(_ code: String) -> StrictClaimDigest?
        func save(_ item: StrictClaimDigest)
        func remove(_ code: String) -> Bool
        func list() -> [StrictClaimDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictClaimDigestStore: StrictClaimDigestStore {
        var items: [String: StrictClaimDigest]
        var order: [String]

        init(items: [String: StrictClaimDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictClaimDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictClaimDigest) {
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

        func list() -> [StrictClaimDigest] {
            var out: [StrictClaimDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictClaimDigestStore() -> any StrictClaimDigestStore {
        return MemoryStrictClaimDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictClaimDigestStore: StrictClaimDigestStore {
        var inner: MemoryStrictClaimDigestStore
        var cache: TTLCache<StrictClaimDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictClaimDigestStore, cache: TTLCache<StrictClaimDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictClaimDigest? {
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

        func save(_ item: StrictClaimDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictClaimDigest] {
            return inner.list()
        }
    }

    static func newCachedStrictClaimDigestStore(_ inner: MemoryStrictClaimDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictClaimDigestStore {
        return CachedStrictClaimDigestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict claim digests. Empty fields match all.
    final class StrictClaimDigestQuery {
        var segment: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minBudget: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictClaimDigest) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictClaimDigest]) -> [StrictClaimDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictClaimDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictClaimDigests(_ store: any StrictClaimDigestStore, query: StrictClaimDigestQuery) -> [StrictClaimDigest] {
        return query.apply(store.list())
    }
}
