import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps regional float pool variances by code.
    protocol RegionalFloatPoolVarianceStore {
        func find(_ code: String) -> RegionalFloatPoolVariance?
        func save(_ item: RegionalFloatPoolVariance)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalFloatPoolVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalFloatPoolVarianceStore: RegionalFloatPoolVarianceStore {
        var items: [String: RegionalFloatPoolVariance]
        var order: [String]

        init(items: [String: RegionalFloatPoolVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalFloatPoolVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalFloatPoolVariance) {
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

        func list() -> [RegionalFloatPoolVariance] {
            var out: [RegionalFloatPoolVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalFloatPoolVarianceStore() -> any RegionalFloatPoolVarianceStore {
        return MemoryRegionalFloatPoolVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalFloatPoolVarianceStore: RegionalFloatPoolVarianceStore {
        var inner: MemoryRegionalFloatPoolVarianceStore
        var cache: TTLCache<RegionalFloatPoolVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalFloatPoolVarianceStore, cache: TTLCache<RegionalFloatPoolVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalFloatPoolVariance? {
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

        func save(_ item: RegionalFloatPoolVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalFloatPoolVariance] {
            return inner.list()
        }
    }

    static func newCachedRegionalFloatPoolVarianceStore(_ inner: MemoryRegionalFloatPoolVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalFloatPoolVarianceStore {
        return CachedRegionalFloatPoolVarianceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional float pool variances. Empty fields match all.
    final class RegionalFloatPoolVarianceQuery {
        var title: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minLimit: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalFloatPoolVariance) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [RegionalFloatPoolVariance]) -> [RegionalFloatPoolVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalFloatPoolVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalFloatPoolVariances(_ store: any RegionalFloatPoolVarianceStore, query: RegionalFloatPoolVarianceQuery) -> [RegionalFloatPoolVariance] {
        return query.apply(store.list())
    }
}
