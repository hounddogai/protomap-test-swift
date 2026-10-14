import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rolling rounding digests by code.
    protocol RollingRoundingDigestStore {
        func find(_ code: String) -> RollingRoundingDigest?
        func save(_ item: RollingRoundingDigest)
        func remove(_ code: String) -> Bool
        func list() -> [RollingRoundingDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingRoundingDigestStore: RollingRoundingDigestStore {
        var items: [String: RollingRoundingDigest]
        var order: [String]

        init(items: [String: RollingRoundingDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingRoundingDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingRoundingDigest) {
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

        func list() -> [RollingRoundingDigest] {
            var out: [RollingRoundingDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingRoundingDigestStore() -> any RollingRoundingDigestStore {
        return MemoryRollingRoundingDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingRoundingDigestStore: RollingRoundingDigestStore {
        var inner: MemoryRollingRoundingDigestStore
        var cache: TTLCache<RollingRoundingDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingRoundingDigestStore, cache: TTLCache<RollingRoundingDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingRoundingDigest? {
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

        func save(_ item: RollingRoundingDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingRoundingDigest] {
            return inner.list()
        }
    }

    static func newCachedRollingRoundingDigestStore(_ inner: MemoryRollingRoundingDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingRoundingDigestStore {
        return CachedRollingRoundingDigestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling rounding digests. Empty fields match all.
    final class RollingRoundingDigestQuery {
        var name: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingRoundingDigest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingRoundingDigest]) -> [RollingRoundingDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingRoundingDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingRoundingDigests(_ store: any RollingRoundingDigestStore, query: RollingRoundingDigestQuery) -> [RollingRoundingDigest] {
        return query.apply(store.list())
    }
}
