import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up digests by code.
    protocol FollowUpDigestStore {
        func find(_ code: String) -> FollowUpDigest?
        func save(_ item: FollowUpDigest)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpDigestStore: FollowUpDigestStore {
        var items: [String: FollowUpDigest]
        var order: [String]

        init(items: [String: FollowUpDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpDigest) {
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

        func list() -> [FollowUpDigest] {
            var out: [FollowUpDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpDigestStore() -> any FollowUpDigestStore {
        return MemoryFollowUpDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpDigestStore: FollowUpDigestStore {
        var inner: MemoryFollowUpDigestStore
        var cache: TTLCache<FollowUpDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpDigestStore, cache: TTLCache<FollowUpDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpDigest? {
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

        func save(_ item: FollowUpDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpDigest] {
            return inner.list()
        }
    }

    static func newCachedFollowUpDigestStore(_ inner: MemoryFollowUpDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpDigestStore {
        return CachedFollowUpDigestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up digests. Empty fields match all.
    final class FollowUpDigestQuery {
        var segment: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpDigest) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpDigest]) -> [FollowUpDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpDigests(_ store: any FollowUpDigestStore, query: FollowUpDigestQuery) -> [FollowUpDigest] {
        return query.apply(store.list())
    }
}
