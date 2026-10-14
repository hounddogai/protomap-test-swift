import AcmePlatform
import Foundation

extension Labs {
    /// Keeps regional result digests by code.
    protocol RegionalResultDigestStore {
        func find(_ code: String) -> RegionalResultDigest?
        func save(_ item: RegionalResultDigest)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalResultDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalResultDigestStore: RegionalResultDigestStore {
        var items: [String: RegionalResultDigest]
        var order: [String]

        init(items: [String: RegionalResultDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalResultDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalResultDigest) {
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

        func list() -> [RegionalResultDigest] {
            var out: [RegionalResultDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalResultDigestStore() -> any RegionalResultDigestStore {
        return MemoryRegionalResultDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalResultDigestStore: RegionalResultDigestStore {
        var inner: MemoryRegionalResultDigestStore
        var cache: TTLCache<RegionalResultDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalResultDigestStore, cache: TTLCache<RegionalResultDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalResultDigest? {
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

        func save(_ item: RegionalResultDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalResultDigest] {
            return inner.list()
        }
    }

    static func newCachedRegionalResultDigestStore(_ inner: MemoryRegionalResultDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalResultDigestStore {
        return CachedRegionalResultDigestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional result digests. Empty fields match all.
    final class RegionalResultDigestQuery {
        var locale: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalResultDigest) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [RegionalResultDigest]) -> [RegionalResultDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalResultDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalResultDigests(_ store: any RegionalResultDigestStore, query: RegionalResultDigestQuery) -> [RegionalResultDigest] {
        return query.apply(store.list())
    }
}
