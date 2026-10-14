import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps primary census variances by code.
    protocol PrimaryCensusVarianceStore {
        func find(_ code: String) -> PrimaryCensusVariance?
        func save(_ item: PrimaryCensusVariance)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryCensusVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryCensusVarianceStore: PrimaryCensusVarianceStore {
        var items: [String: PrimaryCensusVariance]
        var order: [String]

        init(items: [String: PrimaryCensusVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryCensusVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryCensusVariance) {
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

        func list() -> [PrimaryCensusVariance] {
            var out: [PrimaryCensusVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryCensusVarianceStore() -> any PrimaryCensusVarianceStore {
        return MemoryPrimaryCensusVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryCensusVarianceStore: PrimaryCensusVarianceStore {
        var inner: MemoryPrimaryCensusVarianceStore
        var cache: TTLCache<PrimaryCensusVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryCensusVarianceStore, cache: TTLCache<PrimaryCensusVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryCensusVariance? {
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

        func save(_ item: PrimaryCensusVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryCensusVariance] {
            return inner.list()
        }
    }

    static func newCachedPrimaryCensusVarianceStore(_ inner: MemoryPrimaryCensusVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryCensusVarianceStore {
        return CachedPrimaryCensusVarianceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary census variances. Empty fields match all.
    final class PrimaryCensusVarianceQuery {
        var country: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minVersion: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryCensusVariance) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryCensusVariance]) -> [PrimaryCensusVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryCensusVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryCensusVariances(_ store: any PrimaryCensusVarianceStore, query: PrimaryCensusVarianceQuery) -> [PrimaryCensusVariance] {
        return query.apply(store.list())
    }
}
