import AcmePlatform
import Foundation

extension Labs {
    /// Keeps primary courier digests by code.
    protocol PrimaryCourierDigestStore {
        func find(_ code: String) -> PrimaryCourierDigest?
        func save(_ item: PrimaryCourierDigest)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryCourierDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryCourierDigestStore: PrimaryCourierDigestStore {
        var items: [String: PrimaryCourierDigest]
        var order: [String]

        init(items: [String: PrimaryCourierDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryCourierDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryCourierDigest) {
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

        func list() -> [PrimaryCourierDigest] {
            var out: [PrimaryCourierDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryCourierDigestStore() -> any PrimaryCourierDigestStore {
        return MemoryPrimaryCourierDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryCourierDigestStore: PrimaryCourierDigestStore {
        var inner: MemoryPrimaryCourierDigestStore
        var cache: TTLCache<PrimaryCourierDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryCourierDigestStore, cache: TTLCache<PrimaryCourierDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryCourierDigest? {
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

        func save(_ item: PrimaryCourierDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryCourierDigest] {
            return inner.list()
        }
    }

    static func newCachedPrimaryCourierDigestStore(_ inner: MemoryPrimaryCourierDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryCourierDigestStore {
        return CachedPrimaryCourierDigestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary courier digests. Empty fields match all.
    final class PrimaryCourierDigestQuery {
        var source: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minLimit: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryCourierDigest) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryCourierDigest]) -> [PrimaryCourierDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryCourierDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryCourierDigests(_ store: any PrimaryCourierDigestStore, query: PrimaryCourierDigestQuery) -> [PrimaryCourierDigest] {
        return query.apply(store.list())
    }
}
