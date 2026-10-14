import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy digests by code.
    protocol ProxyDigestStore {
        func find(_ code: String) -> ProxyDigest?
        func save(_ item: ProxyDigest)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyDigestStore: ProxyDigestStore {
        var items: [String: ProxyDigest]
        var order: [String]

        init(items: [String: ProxyDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyDigest) {
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

        func list() -> [ProxyDigest] {
            var out: [ProxyDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyDigestStore() -> any ProxyDigestStore {
        return MemoryProxyDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyDigestStore: ProxyDigestStore {
        var inner: MemoryProxyDigestStore
        var cache: TTLCache<ProxyDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyDigestStore, cache: TTLCache<ProxyDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyDigest? {
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

        func save(_ item: ProxyDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyDigest] {
            return inner.list()
        }
    }

    static func newCachedProxyDigestStore(_ inner: MemoryProxyDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyDigestStore {
        return CachedProxyDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy digests. Empty fields match all.
    final class ProxyDigestQuery {
        var title: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMargin: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyDigest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProxyDigest]) -> [ProxyDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyDigests(_ store: any ProxyDigestStore, query: ProxyDigestQuery) -> [ProxyDigest] {
        return query.apply(store.list())
    }
}
