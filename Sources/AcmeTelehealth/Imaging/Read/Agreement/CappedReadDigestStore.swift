import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps capped read digests by code.
    protocol CappedReadDigestStore {
        func find(_ code: String) -> CappedReadDigest?
        func save(_ item: CappedReadDigest)
        func remove(_ code: String) -> Bool
        func list() -> [CappedReadDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedReadDigestStore: CappedReadDigestStore {
        var items: [String: CappedReadDigest]
        var order: [String]

        init(items: [String: CappedReadDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedReadDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedReadDigest) {
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

        func list() -> [CappedReadDigest] {
            var out: [CappedReadDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedReadDigestStore() -> any CappedReadDigestStore {
        return MemoryCappedReadDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedReadDigestStore: CappedReadDigestStore {
        var inner: MemoryCappedReadDigestStore
        var cache: TTLCache<CappedReadDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedReadDigestStore, cache: TTLCache<CappedReadDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedReadDigest? {
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

        func save(_ item: CappedReadDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedReadDigest] {
            return inner.list()
        }
    }

    static func newCachedCappedReadDigestStore(_ inner: MemoryCappedReadDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedReadDigestStore {
        return CachedCappedReadDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped read digests. Empty fields match all.
    final class CappedReadDigestQuery {
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

        func matches(_ item: CappedReadDigest) -> Bool {
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

        func apply(_ items: [CappedReadDigest]) -> [CappedReadDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedReadDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedReadDigests(_ store: any CappedReadDigestStore, query: CappedReadDigestQuery) -> [CappedReadDigest] {
        return query.apply(store.list())
    }
}
