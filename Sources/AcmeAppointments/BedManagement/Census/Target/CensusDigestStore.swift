import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps census digests by code.
    protocol CensusDigestStore {
        func find(_ code: String) -> CensusDigest?
        func save(_ item: CensusDigest)
        func remove(_ code: String) -> Bool
        func list() -> [CensusDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCensusDigestStore: CensusDigestStore {
        var items: [String: CensusDigest]
        var order: [String]

        init(items: [String: CensusDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CensusDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CensusDigest) {
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

        func list() -> [CensusDigest] {
            var out: [CensusDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCensusDigestStore() -> any CensusDigestStore {
        return MemoryCensusDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCensusDigestStore: CensusDigestStore {
        var inner: MemoryCensusDigestStore
        var cache: TTLCache<CensusDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryCensusDigestStore, cache: TTLCache<CensusDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CensusDigest? {
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

        func save(_ item: CensusDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CensusDigest] {
            return inner.list()
        }
    }

    static func newCachedCensusDigestStore(_ inner: MemoryCensusDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CensusDigestStore {
        return CachedCensusDigestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects census digests. Empty fields match all.
    final class CensusDigestQuery {
        var facility: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minRatio: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CensusDigest) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CensusDigest]) -> [CensusDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CensusDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCensusDigests(_ store: any CensusDigestStore, query: CensusDigestQuery) -> [CensusDigest] {
        return query.apply(store.list())
    }
}
