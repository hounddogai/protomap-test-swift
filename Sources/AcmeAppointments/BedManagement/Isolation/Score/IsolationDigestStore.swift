import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation digests by code.
    protocol IsolationDigestStore {
        func find(_ code: String) -> IsolationDigest?
        func save(_ item: IsolationDigest)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationDigestStore: IsolationDigestStore {
        var items: [String: IsolationDigest]
        var order: [String]

        init(items: [String: IsolationDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationDigest) {
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

        func list() -> [IsolationDigest] {
            var out: [IsolationDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationDigestStore() -> any IsolationDigestStore {
        return MemoryIsolationDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationDigestStore: IsolationDigestStore {
        var inner: MemoryIsolationDigestStore
        var cache: TTLCache<IsolationDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationDigestStore, cache: TTLCache<IsolationDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationDigest? {
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

        func save(_ item: IsolationDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationDigest] {
            return inner.list()
        }
    }

    static func newCachedIsolationDigestStore(_ inner: MemoryIsolationDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationDigestStore {
        return CachedIsolationDigestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation digests. Empty fields match all.
    final class IsolationDigestQuery {
        var locale: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationDigest) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [IsolationDigest]) -> [IsolationDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationDigests(_ store: any IsolationDigestStore, query: IsolationDigestQuery) -> [IsolationDigest] {
        return query.apply(store.list())
    }
}
