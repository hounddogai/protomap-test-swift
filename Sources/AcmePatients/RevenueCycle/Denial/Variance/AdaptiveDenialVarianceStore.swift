import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps adaptive denial variances by code.
    protocol AdaptiveDenialVarianceStore {
        func find(_ code: String) -> AdaptiveDenialVariance?
        func save(_ item: AdaptiveDenialVariance)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveDenialVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveDenialVarianceStore: AdaptiveDenialVarianceStore {
        var items: [String: AdaptiveDenialVariance]
        var order: [String]

        init(items: [String: AdaptiveDenialVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveDenialVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveDenialVariance) {
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

        func list() -> [AdaptiveDenialVariance] {
            var out: [AdaptiveDenialVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveDenialVarianceStore() -> any AdaptiveDenialVarianceStore {
        return MemoryAdaptiveDenialVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveDenialVarianceStore: AdaptiveDenialVarianceStore {
        var inner: MemoryAdaptiveDenialVarianceStore
        var cache: TTLCache<AdaptiveDenialVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveDenialVarianceStore, cache: TTLCache<AdaptiveDenialVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveDenialVariance? {
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

        func save(_ item: AdaptiveDenialVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveDenialVariance] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveDenialVarianceStore(_ inner: MemoryAdaptiveDenialVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveDenialVarianceStore {
        return CachedAdaptiveDenialVarianceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive denial variances. Empty fields match all.
    final class AdaptiveDenialVarianceQuery {
        var facility: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minRetries: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveDenialVariance) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveDenialVariance]) -> [AdaptiveDenialVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveDenialVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveDenialVariances(_ store: any AdaptiveDenialVarianceStore, query: AdaptiveDenialVarianceQuery) -> [AdaptiveDenialVariance] {
        return query.apply(store.list())
    }
}
