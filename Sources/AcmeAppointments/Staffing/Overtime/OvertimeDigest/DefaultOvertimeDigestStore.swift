import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps default overtime digests by code.
    protocol DefaultOvertimeDigestStore {
        func find(_ code: String) -> DefaultOvertimeDigest?
        func save(_ item: DefaultOvertimeDigest)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultOvertimeDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultOvertimeDigestStore: DefaultOvertimeDigestStore {
        var items: [String: DefaultOvertimeDigest]
        var order: [String]

        init(items: [String: DefaultOvertimeDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultOvertimeDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultOvertimeDigest) {
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

        func list() -> [DefaultOvertimeDigest] {
            var out: [DefaultOvertimeDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultOvertimeDigestStore() -> any DefaultOvertimeDigestStore {
        return MemoryDefaultOvertimeDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultOvertimeDigestStore: DefaultOvertimeDigestStore {
        var inner: MemoryDefaultOvertimeDigestStore
        var cache: TTLCache<DefaultOvertimeDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultOvertimeDigestStore, cache: TTLCache<DefaultOvertimeDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultOvertimeDigest? {
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

        func save(_ item: DefaultOvertimeDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultOvertimeDigest] {
            return inner.list()
        }
    }

    static func newCachedDefaultOvertimeDigestStore(_ inner: MemoryDefaultOvertimeDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultOvertimeDigestStore {
        return CachedDefaultOvertimeDigestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default overtime digests. Empty fields match all.
    final class DefaultOvertimeDigestQuery {
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

        func matches(_ item: DefaultOvertimeDigest) -> Bool {
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

        func apply(_ items: [DefaultOvertimeDigest]) -> [DefaultOvertimeDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultOvertimeDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultOvertimeDigests(_ store: any DefaultOvertimeDigestStore, query: DefaultOvertimeDigestQuery) -> [DefaultOvertimeDigest] {
        return query.apply(store.list())
    }
}
