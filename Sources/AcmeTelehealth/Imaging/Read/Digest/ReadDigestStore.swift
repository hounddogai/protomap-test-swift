import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read digests by code.
    protocol ReadDigestStore {
        func find(_ code: String) -> ReadDigest?
        func save(_ item: ReadDigest)
        func remove(_ code: String) -> Bool
        func list() -> [ReadDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadDigestStore: ReadDigestStore {
        var items: [String: ReadDigest]
        var order: [String]

        init(items: [String: ReadDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadDigest) {
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

        func list() -> [ReadDigest] {
            var out: [ReadDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadDigestStore() -> any ReadDigestStore {
        return MemoryReadDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadDigestStore: ReadDigestStore {
        var inner: MemoryReadDigestStore
        var cache: TTLCache<ReadDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadDigestStore, cache: TTLCache<ReadDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadDigest? {
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

        func save(_ item: ReadDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadDigest] {
            return inner.list()
        }
    }

    static func newCachedReadDigestStore(_ inner: MemoryReadDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadDigestStore {
        return CachedReadDigestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects read digests. Empty fields match all.
    final class ReadDigestQuery {
        var name: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRate: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadDigest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReadDigest]) -> [ReadDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadDigests(_ store: any ReadDigestStore, query: ReadDigestQuery) -> [ReadDigest] {
        return query.apply(store.list())
    }
}
