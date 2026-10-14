import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps census bundles by code.
    protocol CensusBundleStore {
        func find(_ code: String) -> CensusBundle?
        func save(_ item: CensusBundle)
        func remove(_ code: String) -> Bool
        func list() -> [CensusBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCensusBundleStore: CensusBundleStore {
        var items: [String: CensusBundle]
        var order: [String]

        init(items: [String: CensusBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CensusBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CensusBundle) {
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

        func list() -> [CensusBundle] {
            var out: [CensusBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCensusBundleStore() -> any CensusBundleStore {
        return MemoryCensusBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCensusBundleStore: CensusBundleStore {
        var inner: MemoryCensusBundleStore
        var cache: TTLCache<CensusBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryCensusBundleStore, cache: TTLCache<CensusBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CensusBundle? {
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

        func save(_ item: CensusBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CensusBundle] {
            return inner.list()
        }
    }

    static func newCachedCensusBundleStore(_ inner: MemoryCensusBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CensusBundleStore {
        return CachedCensusBundleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects census bundles. Empty fields match all.
    final class CensusBundleQuery {
        var channel: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CensusBundle) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CensusBundle]) -> [CensusBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CensusBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCensusBundles(_ store: any CensusBundleStore, query: CensusBundleQuery) -> [CensusBundle] {
        return query.apply(store.list())
    }
}
