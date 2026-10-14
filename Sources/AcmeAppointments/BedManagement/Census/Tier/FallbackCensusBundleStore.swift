import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps fallback census bundles by code.
    protocol FallbackCensusBundleStore {
        func find(_ code: String) -> FallbackCensusBundle?
        func save(_ item: FallbackCensusBundle)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackCensusBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackCensusBundleStore: FallbackCensusBundleStore {
        var items: [String: FallbackCensusBundle]
        var order: [String]

        init(items: [String: FallbackCensusBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackCensusBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackCensusBundle) {
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

        func list() -> [FallbackCensusBundle] {
            var out: [FallbackCensusBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackCensusBundleStore() -> any FallbackCensusBundleStore {
        return MemoryFallbackCensusBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackCensusBundleStore: FallbackCensusBundleStore {
        var inner: MemoryFallbackCensusBundleStore
        var cache: TTLCache<FallbackCensusBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackCensusBundleStore, cache: TTLCache<FallbackCensusBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackCensusBundle? {
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

        func save(_ item: FallbackCensusBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackCensusBundle] {
            return inner.list()
        }
    }

    static func newCachedFallbackCensusBundleStore(_ inner: MemoryFallbackCensusBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackCensusBundleStore {
        return CachedFallbackCensusBundleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback census bundles. Empty fields match all.
    final class FallbackCensusBundleQuery {
        var name: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackCensusBundle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackCensusBundle]) -> [FallbackCensusBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackCensusBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackCensusBundles(_ store: any FallbackCensusBundleStore, query: FallbackCensusBundleQuery) -> [FallbackCensusBundle] {
        return query.apply(store.list())
    }
}
