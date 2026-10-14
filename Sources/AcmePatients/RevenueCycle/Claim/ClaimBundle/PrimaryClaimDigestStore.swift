import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps primary claim digests by code.
    protocol PrimaryClaimDigestStore {
        func find(_ code: String) -> PrimaryClaimDigest?
        func save(_ item: PrimaryClaimDigest)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryClaimDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryClaimDigestStore: PrimaryClaimDigestStore {
        var items: [String: PrimaryClaimDigest]
        var order: [String]

        init(items: [String: PrimaryClaimDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryClaimDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryClaimDigest) {
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

        func list() -> [PrimaryClaimDigest] {
            var out: [PrimaryClaimDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryClaimDigestStore() -> any PrimaryClaimDigestStore {
        return MemoryPrimaryClaimDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryClaimDigestStore: PrimaryClaimDigestStore {
        var inner: MemoryPrimaryClaimDigestStore
        var cache: TTLCache<PrimaryClaimDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryClaimDigestStore, cache: TTLCache<PrimaryClaimDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryClaimDigest? {
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

        func save(_ item: PrimaryClaimDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryClaimDigest] {
            return inner.list()
        }
    }

    static func newCachedPrimaryClaimDigestStore(_ inner: MemoryPrimaryClaimDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryClaimDigestStore {
        return CachedPrimaryClaimDigestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary claim digests. Empty fields match all.
    final class PrimaryClaimDigestQuery {
        var title: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryClaimDigest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryClaimDigest]) -> [PrimaryClaimDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryClaimDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryClaimDigests(_ store: any PrimaryClaimDigestStore, query: PrimaryClaimDigestQuery) -> [PrimaryClaimDigest] {
        return query.apply(store.list())
    }
}
